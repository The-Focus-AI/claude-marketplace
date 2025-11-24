package main

import (
	"bufio"
	"bytes"
	"encoding/base64"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

const apiURL = "https://generativelanguage.googleapis.com/v1beta/models"

var configDir = filepath.Join(os.Getenv("HOME"), ".config", "gemini-image")

func main() {
	input := flag.String("i", "", "Input image for editing")
	useLast := flag.Bool("L", false, "Use last generated image as input")
	prompt := flag.String("p", "", "Prompt text")
	promptFile := flag.String("f", "", "Read prompt from file")
	output := flag.String("o", "output.png", "Output filename")
	modelFlag := flag.String("m", "", "Model to use (see -l for list)")
	listModels := flag.Bool("l", false, "List available image models")
	resetConfig := flag.Bool("reset", false, "Reset saved API key and model")
	flag.Parse()

	// Handle reset
	if *resetConfig {
		os.RemoveAll(configDir)
		fmt.Fprintln(os.Stderr, "Config reset. Will prompt for API key and model on next run.")
		return
	}

	// Handle -L flag: use last generated image
	if *useLast {
		lastPath := getLastOutput()
		if lastPath == "" {
			fatal("No previous image found. Generate one first.")
		}
		fmt.Fprintf(os.Stderr, "Using last output: %s\n", lastPath)
		*input = lastPath
	}

	// Get API key first (needed for listing models too)
	apiKey, err := getAPIKey()
	if err != nil {
		fatal("Failed to get API key: %v", err)
	}

	// Handle list models
	if *listModels {
		models, err := listImageModels(apiKey)
		if err != nil {
			fatal("Failed to list models: %v", err)
		}
		fmt.Println("Available image generation models:")
		for _, m := range models {
			fmt.Printf("  %s\n", m.Name)
			if m.Description != "" {
				fmt.Printf("    %s\n", truncate(m.Description, 70))
			}
		}
		return
	}

	// Get prompt
	promptText := *prompt
	if *promptFile != "" {
		data, err := os.ReadFile(*promptFile)
		if err != nil {
			fatal("Cannot read prompt file: %v", err)
		}
		promptText = string(data)
	}
	if promptText == "" {
		fmt.Fprintln(os.Stderr, "Usage: go run main.go -p \"prompt\" -o output.png")
		fmt.Fprintln(os.Stderr, "       go run main.go -i input.jpg -p \"prompt\" -o output.png")
		fmt.Fprintln(os.Stderr, "       go run main.go -L -p \"change style\" -o output.png  # uses last image")
		fmt.Fprintln(os.Stderr, "\nOptions:")
		flag.PrintDefaults()
		os.Exit(1)
	}

	// Get model (from flag, cache, or prompt user)
	model, err := getModel(apiKey, *modelFlag)
	if err != nil {
		fatal("Failed to get model: %v", err)
	}

	// Build request
	parts := []any{map[string]string{"text": promptText}}

	// Add input image if provided
	if *input != "" {
		imgData, err := os.ReadFile(*input)
		if err != nil {
			fatal("Cannot read input image '%s': %v", *input, err)
		}
		parts = append(parts, map[string]any{
			"inlineData": map[string]string{
				"mimeType": mimeType(*input),
				"data":     base64.StdEncoding.EncodeToString(imgData),
			},
		})
		fmt.Fprintf(os.Stderr, "Input: %s\n", *input)
	}

	fmt.Fprintf(os.Stderr, "Prompt: %s\n", truncate(promptText, 60))
	fmt.Fprintf(os.Stderr, "Model: %s\n", model)

	// Call API
	reqBody := map[string]any{
		"contents":         []any{map[string]any{"parts": parts}},
		"generationConfig": map[string]any{"responseModalities": []string{"image", "text"}},
	}
	reqJSON, _ := json.Marshal(reqBody)

	resp, err := http.Post(
		fmt.Sprintf("%s/%s:generateContent?key=%s", apiURL, model, apiKey),
		"application/json",
		bytes.NewReader(reqJSON),
	)
	if err != nil {
		fatal("API request failed: %v", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != 200 {
		fatal("API error %d: %s", resp.StatusCode, string(body))
	}

	// Parse response
	var result struct {
		Candidates []struct {
			Content struct {
				Parts []struct {
					Text       string `json:"text,omitempty"`
					InlineData *struct {
						Data string `json:"data"`
					} `json:"inlineData,omitempty"`
				} `json:"parts"`
			} `json:"content"`
		} `json:"candidates"`
	}
	if err := json.Unmarshal(body, &result); err != nil {
		fatal("Failed to parse response: %v", err)
	}

	// Resolve output path to absolute before writing
	outputPath := *output
	if !filepath.IsAbs(outputPath) {
		if abs, err := filepath.Abs(outputPath); err == nil {
			outputPath = abs
		}
	}

	// Extract and save image
	saved := false
	for _, cand := range result.Candidates {
		for _, part := range cand.Content.Parts {
			if part.Text != "" {
				fmt.Fprintf(os.Stderr, "Response: %s\n", part.Text)
			}
			if part.InlineData != nil {
				imgData, err := base64.StdEncoding.DecodeString(part.InlineData.Data)
				if err != nil {
					fatal("Failed to decode image: %v", err)
				}
				// Ensure output directory exists
				if dir := filepath.Dir(outputPath); dir != "." {
					os.MkdirAll(dir, 0755)
				}
				if err := os.WriteFile(outputPath, imgData, 0644); err != nil {
					fatal("Failed to write output: %v", err)
				}
				// Save as last output for future edits
				saveLastOutput(outputPath)
				fmt.Println(outputPath)
				saved = true
			}
		}
	}

	if !saved {
		fatal("No image in response:\n%s", string(body))
	}
}

// Model represents a Gemini model
type Model struct {
	Name                       string   `json:"name"`
	DisplayName                string   `json:"displayName"`
	Description                string   `json:"description"`
	SupportedGenerationMethods []string `json:"supportedGenerationMethods"`
}

func listImageModels(apiKey string) ([]Model, error) {
	resp, err := http.Get(fmt.Sprintf("%s?key=%s", apiURL, apiKey))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("API error %d: %s", resp.StatusCode, string(body))
	}

	var result struct {
		Models []Model `json:"models"`
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}

	// Filter for image-capable models
	var imageModels []Model
	for _, m := range result.Models {
		// Check if model name suggests image capability
		name := strings.ToLower(m.Name)
		desc := strings.ToLower(m.Description)
		if strings.Contains(name, "image") ||
			strings.Contains(desc, "image generation") ||
			strings.Contains(desc, "generate images") {
			// Strip "models/" prefix for cleaner display
			m.Name = strings.TrimPrefix(m.Name, "models/")
			imageModels = append(imageModels, m)
		}
	}

	// Sort by name
	sort.Slice(imageModels, func(i, j int) bool {
		return imageModels[i].Name < imageModels[j].Name
	})

	return imageModels, nil
}

func getModel(apiKey, flagModel string) (string, error) {
	// If model specified via flag, use it and cache it
	if flagModel != "" {
		cacheModel(flagModel)
		return flagModel, nil
	}

	// Check for cached model
	modelPath := filepath.Join(configDir, "model")
	if data, err := os.ReadFile(modelPath); err == nil {
		model := strings.TrimSpace(string(data))
		if model != "" {
			return model, nil
		}
	}

	// Prompt user to select
	fmt.Fprintln(os.Stderr, "Fetching available image models...")
	models, err := listImageModels(apiKey)
	if err != nil {
		return "", err
	}

	if len(models) == 0 {
		return "", fmt.Errorf("no image generation models found")
	}

	fmt.Fprintln(os.Stderr, "\nAvailable image generation models:")
	for i, m := range models {
		fmt.Fprintf(os.Stderr, "  [%d] %s\n", i+1, m.Name)
	}
	fmt.Fprint(os.Stderr, "\nSelect model number: ")

	reader := bufio.NewReader(os.Stdin)
	input, _ := reader.ReadString('\n')
	input = strings.TrimSpace(input)

	var choice int
	if _, err := fmt.Sscanf(input, "%d", &choice); err != nil || choice < 1 || choice > len(models) {
		return "", fmt.Errorf("invalid selection")
	}

	selected := models[choice-1].Name
	cacheModel(selected)
	return selected, nil
}

func cacheModel(model string) {
	modelPath := filepath.Join(configDir, "model")
	os.MkdirAll(configDir, 0755)
	os.WriteFile(modelPath, []byte(model), 0600)
}

func getLastOutput() string {
	data, err := os.ReadFile(filepath.Join(configDir, "last-output"))
	if err != nil {
		return ""
	}
	path := strings.TrimSpace(string(data))
	// Verify file still exists
	if _, err := os.Stat(path); err != nil {
		fmt.Fprintf(os.Stderr, "Warning: last output file no longer exists: %s\n", path)
		return ""
	}
	return path
}

func saveLastOutput(path string) {
	os.MkdirAll(configDir, 0755)
	os.WriteFile(filepath.Join(configDir, "last-output"), []byte(path), 0600)
}

func loadEnvFile() {
	// Try .env in current directory, then walk up to find one
	dir, _ := os.Getwd()
	for {
		envPath := filepath.Join(dir, ".env")
		if data, err := os.ReadFile(envPath); err == nil {
			for _, line := range strings.Split(string(data), "\n") {
				line = strings.TrimSpace(line)
				if line == "" || strings.HasPrefix(line, "#") {
					continue
				}
				if idx := strings.Index(line, "="); idx > 0 {
					key := strings.TrimSpace(line[:idx])
					val := strings.TrimSpace(line[idx+1:])
					// Remove quotes if present
					val = strings.Trim(val, "\"'")
					if os.Getenv(key) == "" {
						os.Setenv(key, val)
					}
				}
			}
			return
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}
}

func getAPIKey() (string, error) {
	// Load .env file first (won't override existing env vars)
	loadEnvFile()

	// Check environment variables (GEMINI_API_KEY or GOOGLE_API_KEY)
	if key := os.Getenv("GEMINI_API_KEY"); key != "" {
		return key, nil
	}
	if key := os.Getenv("GOOGLE_API_KEY"); key != "" {
		return key, nil
	}

	return "", fmt.Errorf("no API key found. Set GEMINI_API_KEY or GOOGLE_API_KEY environment variable, or create a .env file")
}

func mimeType(filename string) string {
	types := map[string]string{
		".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png",
		".gif": "image/gif", ".webp": "image/webp", ".heic": "image/heic",
	}
	if t, ok := types[strings.ToLower(filepath.Ext(filename))]; ok {
		return t
	}
	return "image/jpeg"
}

func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n] + "..."
}

func fatal(format string, args ...any) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(1)
}
