#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define SECTOR_SIZE 2048

// Primary Volume Descriptor (PVD) structure
typedef struct __attribute__((packed)) {
    uint8_t type;                        // Offset 0
    char id[5];                          // Offset 1
    uint8_t version;                     // Offset 6
    uint8_t unused1;                     // Offset 7
    char system_id[32];                  // Offset 8
    char volume_id[32];                  // Offset 40
    uint8_t unused2[8];                  // Offset 72
    uint32_t volume_space_size_le;       // Offset 80 (little-endian)
    uint32_t volume_space_size_be;       // Offset 84 (big-endian)
    uint8_t unused3[32];                 // Offset 88
    uint16_t volume_set_size_le;         // Offset 120 (little-endian)
    uint16_t volume_set_size_be;         // Offset 122 (big-endian)
    uint16_t volume_sequence_number_le;  // Offset 124 (little-endian)
    uint16_t volume_sequence_number_be;  // Offset 126 (big-endian)
    uint16_t logical_block_size_le;      // Offset 128 (little-endian)
    uint16_t logical_block_size_be;      // Offset 130 (big-endian)
    uint32_t path_table_size_le;         // Offset 132 (little-endian)
    uint32_t path_table_size_be;         // Offset 136 (big-endian)
    uint32_t type_l_path_table;          // Offset 140
    uint32_t opt_type_l_path_table;      // Offset 144
    uint32_t type_m_path_table;          // Offset 148
    uint32_t opt_type_m_path_table;      // Offset 152
    uint8_t root_directory_record[34];   // Offset 156
    char volume_set_id[128];             // Offset 190
    char publisher_id[128];              // Offset 318
    char data_preparer_id[128];          // Offset 446
    char application_id[128];            // Offset 574
    char copyright_file_id[37];          // Offset 702
    char abstract_file_id[37];           // Offset 739
    char bibliographic_file_id[37];      // Offset 776
    char creation_date[17];              // Offset 813
    char modification_date[17];          // Offset 830
    char expiration_date[17];            // Offset 847
    char effective_date[17];             // Offset 864
    uint8_t file_structure_version;      // Offset 881
    uint8_t unused4;                     // Offset 882
    uint8_t application_data[512];       // Offset 883
    uint8_t unused5[653];                // Offset 1395
} PVD;

// Directory Record structure
typedef struct __attribute__((packed)) {
    uint8_t length;                      // Offset 0
    uint8_t ext_attr_length;             // Offset 1
    uint32_t extent_location_le;         // Offset 2 (little-endian)
    uint32_t extent_location_be;         // Offset 6 (big-endian)
    uint32_t data_length_le;             // Offset 10 (little-endian)
    uint32_t data_length_be;             // Offset 14 (big-endian)
    uint8_t recording_date[7];           // Offset 18
    uint8_t file_flags;                  // Offset 25
    uint8_t file_unit_size;              // Offset 26
    uint8_t interleave_gap_size;         // Offset 27
    uint16_t volume_sequence_number_le;  // Offset 28 (little-endian)
    uint16_t volume_sequence_number_be;  // Offset 30 (big-endian)
    uint8_t file_id_length;              // Offset 32
    char file_id[];                      // Offset 33
} DirectoryRecord;

// Function to read the Primary Volume Descriptor
void read_pvd(FILE *iso_file, PVD *pvd) {
    fseek(iso_file, 16 * SECTOR_SIZE, SEEK_SET); // Seek to sector 16
    fread(pvd, sizeof(PVD), 1, iso_file);        // Read the PVD
}

// Function to print the Primary Volume Descriptor
void print_pvd(PVD *pvd) {
    printf("Volume ID: %.32s\n", pvd->volume_id);
    printf("Volume Space Size (LE): %u\n", pvd->volume_space_size_le);
    printf("Volume Space Size (BE): %u\n", pvd->volume_space_size_be);
}

// Function to read a sector from the ISO file
void read_sector(FILE *iso_file, uint32_t sector, void *buffer) {
    fseek(iso_file, sector * SECTOR_SIZE, SEEK_SET);
    fread(buffer, SECTOR_SIZE, 1, iso_file);
}

// Function to print directory entries
void print_directory_entries(FILE *iso_file, uint8_t *root_directory_record) {
    uint32_t extent_location = *((uint32_t *)(root_directory_record + 2));
    uint32_t data_length = *((uint32_t *)(root_directory_record + 10));
    printf("Root Directory Data Length: %u\n", data_length);
    uint8_t buffer[SECTOR_SIZE];

    for (uint32_t i = 0; i < data_length; i += SECTOR_SIZE) {
        read_sector(iso_file, extent_location + (i / SECTOR_SIZE), buffer);
        uint8_t *ptr = buffer;

        while (ptr < buffer + SECTOR_SIZE && ptr[0] != 0) {
            DirectoryRecord *record = (DirectoryRecord *)ptr;
            printf("File ID Length: %u\n", record->file_id_length);
            printf("File ID: %.*s\n", record->file_id_length, record->file_id);
            printf("Extent Location (LE): %u\n", record->extent_location_le);
            printf("Data Length (LE): %u\n", record->data_length_le);
            printf("File Flags: %u\n", record->file_flags);
            ptr += record->length;
        }
    }
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <iso_file>\n", argv[0]);
        return 1;
    }

    FILE *iso_file = fopen(argv[1], "rb");
    if (!iso_file) {
        perror("Error opening ISO file");
        return 1;
    }

    PVD pvd;
    read_pvd(iso_file, &pvd);
    print_pvd(&pvd);
    print_directory_entries(iso_file, pvd.root_directory_record);

    fclose(iso_file);
    return 0;
}

