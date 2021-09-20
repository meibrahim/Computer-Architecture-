// MARKERS_H
// Mazen Ibrahim
// 295924
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

typedef char char_t;
typedef char_t* string;

typedef bool boolean;
typedef uint32_t uint24_t;

void print_debug(int32_t x, int32_t y) {
	printf("DEBUG::breakpoint(%i, %i)\n", x, y);
}

void print_marker(int32_t x, int32_t y);

uint16_t get_int16(uint8_t buff[], uint32_t offset);
uint24_t get_int24(uint8_t buff[], uint32_t offset);
uint32_t get_int32(uint8_t buff[], uint32_t offset);

int32_t get_bmp_w();
int32_t get_bmp_h();
int32_t get_bmp_s();
int32_t get_pixel(int32_t x, int32_t y);
int32_t get_pixel_offset(int32_t x, int32_t y);

boolean is_black(int32_t x, int32_t y);
int32_t find_black(int32_t x, int32_t y);
int32_t find_color(int32_t x, int32_t y);
int32_t get_width(int32_t x, int32_t y);

int32_t next_marker(int32_t x, int32_t y);
int32_t find_markers(uint8_t* bitmap, uint32_t* x_pos, uint32_t* y_pos);

boolean read_bmp(const char_t* path);

int32_t main(int32_t argc, string* argv);

uint8_t* bitmap;
uint8_t* header;
uint8_t* pixels;

// !MARKERS_H


// MARKERS_IO_C

uint16_t get_int16(uint8_t buff[], uint32_t offset) {
	return buff[offset] | (buff[offset] << 8);
}

uint24_t get_int24(uint8_t buff[], uint32_t offset) {
	return buff[offset] | (buff[offset + 1] << 8) | (buff[offset + 2] << 16);
}

uint32_t get_int32(uint8_t buff[], uint32_t offset) {
	return buff[offset] | (buff[offset + 1] << 8) | (buff[offset + 2] << 16) | (buff[offset + 3] << 24);
}

int32_t get_pixel_offset(int32_t x, int32_t y) {
	int32_t width = get_bmp_w();
	int32_t height = get_bmp_h();
	if (x >= width || y >= height || x < 0 || y < 0) {
		return -1;
	}
	int32_t padding = width % 4;
	if (padding != 0) {
		padding = 4 - padding;
	}
	return (x * 3) + (y * width * 3) + (y * padding);
}

int32_t find_black(int32_t x, int32_t y) {
	while (!is_black(x, y)) {
		if (--x < 0) {
			return -1;
		}
	}
	return x;
}

int32_t find_color(int32_t x, int32_t y) {
	while (is_black(x, y)) {
		if (--x < 0) {
			return -1;
		}
	}
	return x;
}

void print_marker(int32_t x, int32_t y) {
	printf("Found marker at [%i, %i]\n", x, y);
}

void cleanup() {
	if (bitmap != NULL) {
		free(bitmap);
		bitmap = NULL;
		header = NULL;
		pixels = NULL;
	}
}

void print_error(const char_t* err) {
	printf(err);
	cleanup();
}

boolean read_bmp(const char_t* path) {
	const uint32_t header_size = 54;
	FILE* stream = fopen(path, "rb");
	if (stream != NULL) {
		bitmap = (uint8_t*)malloc(header_size);
		header = bitmap;
		if (fread(bitmap, header_size, 1, stream) == 1) {
			int32_t pixels_size = get_int32(bitmap, 0x22);
			uint8_t* newptr = (uint8_t*)realloc(bitmap, header_size + pixels_size);
			if (newptr != NULL) {
				bitmap = newptr;
				header = newptr;
				pixels = newptr + header_size;
				if (fread(pixels, pixels_size, 1, stream) == 1) {
					return true;
				}
				else {
					print_error("Error reading the bmp pixel data");
				}
			}
			else {
				print_error("Error realocating memory");
			}
		}
		else {
			print_error("Error reading the bmp header");
		}
	}
	else {
		print_error("Error opening the provided file\n");
	}
	return false;
}

// !MARKERS_IO_C


// MARKERS_ENTRY
#define MAX_MARKERS 50

int32_t main(int32_t argc, string* argv) {
	const int32_t max_markers = MAX_MARKERS;
	uint32_t x_pos[MAX_MARKERS];
	uint32_t y_pos[MAX_MARKERS];

	if (read_bmp("source.bmp")) {
		uint32_t result = find_markers(bitmap, x_pos, y_pos);

		printf("Found %i markers:\n", result);
		for (uint32_t i = 0; i < result; ++i) {
			print_marker(x_pos[i], y_pos[i]);
		}
		
		cleanup();

		return 0;
	}
	else {
		return -1;
	}
}
// !MARKERS_ENTRY