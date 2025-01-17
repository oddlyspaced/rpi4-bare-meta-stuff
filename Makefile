ARMGNU ?= aarch64-linux-gnu

COPS = -Wall -nostdlib -nostartfiles -ffreestanding -Iinclude -mgeneral-regs-only

ASMOPS = -Iinclude

BUILD_DIR = build
SRC_DIR = src

all : kernel8.img clean_build

clean : clean_armstub
	rm -rf $(BUILD_DIR) *.img

clean_build :
	rm -rf $(BUILD_DIR)

$(BUILD_DIR)/%_c.o: $(SRC_DIR)/%.c
	mkdir -p $(@D)
	$(ARMGNU)-gcc $(COPS) -MMD -c $< -o $@

$(BUILD_DIR)/%_s.o: $(SRC_DIR)/%.S
	mkdir -p $(@D)
	$(ARMGNU)-gcc $(COPS) -MMD -c $< -o $@

C_FILES = $(wildcard $(SRC_DIR)/*.c)
ASM_FILES = $(wildcard $(SRC_DIR)/*.S)
OBJ_FILES = $(C_FILES:$(SRC_DIR)/%.c=$(BUILD_DIR)/%_c.o)
OBJ_FILES += $(ASM_FILES:$(SRC_DIR)/%.S=$(BUILD_DIR)/%_s.o)

DEP_FILES = $(OBJ_FILES:%.o=%.d)
-include $(DEP_FILES)

kernel8.img: $(SRC_DIR)/linker.ld $(OBJ_FILES)
	$(ARMGNU)-ld -T $(SRC_DIR)/linker.ld -o $(BUILD_DIR)/kernel8.elf $(OBJ_FILES)
	$(ARMGNU)-objcopy $(BUILD_DIR)/kernel8.elf -O binary kernel8.img
	@echo "--------------------------------"
	@echo "Finished compiling kernel image."
	@echo "--------------------------------"

clean_armstub :
	rm -rf armstub/build/*

armstub/build/armstub_s.o : armstub/src/armstub.S
	mkdir -p $(@D)
	$(ARMGNU)-gcc $(COPS) -MMD -c $< -o $@

armstub : armstub/build/armstub_s.o
	$(ARMGNU)-ld --section-start=.text=0 -o armstub/build/armstub.elf armstub/build/armstub_s.o
	$(ARMGNU)-objcopy armstub/build/armstub.elf -O binary armstub-custom.bin
	@echo "--------------------------------------"
	@echo "Finished compiling custom stub binary."
	@echo "--------------------------------------"
