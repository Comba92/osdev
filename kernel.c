#define VIDEO_ADDR 0xb8000
#define VIDEO_ROWS 25
#define VIDEO_COLS 80
#define WHITE_ON_BLACK 0x0f

#define REG_SCREEN_CTRL (u8) 0x3d4
#define REG_SCREEN_DATA (u8) 0x3d5

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;

u8 port_byte_in(u8 port) {
    u8 result;
    __asm__("in %%dx, %%al" : "=a" (result) : "d" (port));
    return result;
}

void port_byte_out(u8 port, u8 data) {
    __asm__("out %%al, %%dx" : :"a" (data), "d" (port));
}

u16 port_word_in(u8 port) {
    u16 result;
    __asm__("in %%dx, %%ax" : "=a" (result) : "d" (port));
    return result;
}

void port_word_out(u8 port, u16 data) {
    __asm__("out %%ax, %%dx" : :"a" (data), "d" (port));
}

int get_screen_offset(int col, int row) {
    return 2 * (row * VIDEO_COLS + col);
}

int get_cursor_offset() {
    port_byte_out(REG_SCREEN_CTRL, 14);
    int offset = port_byte_in(REG_SCREEN_DATA) << 8;
    port_byte_out(REG_SCREEN_CTRL, 15);
    offset += port_byte_in(REG_SCREEN_DATA);
    return offset * 2;
}

void set_cursor_offset(int offset) {
    offset /= 2;
    port_byte_out(REG_SCREEN_CTRL, 14);
    port_byte_out(REG_SCREEN_DATA, (u8)(offset >> 8));
    port_byte_out(REG_SCREEN_CTRL, 15);
    port_byte_out(REG_SCREEN_DATA, (u8)(offset & 0xff));
}

int print_char(u8 c, int col, int row, u8 attribute) {
    u8* vmem = (u8*) VIDEO_ADDR;

    if (!attribute) attribute = WHITE_ON_BLACK;

    int offset;
    if (col >= 0 && row >= 0) offset = get_screen_offset(col, row);
    else offset = get_cursor_offset();

    if (c == '\n') {
        int rows = offset / (2*VIDEO_COLS);
        offset = get_screen_offset(79, rows);
    } else {
        vmem[offset] = c;
        vmem[offset+1] = attribute;
        offset += 2;
    }

    // offset = handle_scrolling(offset);
    set_cursor_offset(offset);

    return offset;
}

void print_string(u8 *msg, int col, int row) {
    int offset;
    if (col >= 0 && row >= 0)
        offset = get_screen_offset(col, row);
    else {
        offset = get_cursor_offset();
        row = offset / (2*VIDEO_COLS);
        col = (offset - row * 2 * VIDEO_COLS)/2; 
    }

    int i = 0;
    while (msg[i] != 0) {
        offset = print_char(msg[i], col, row, WHITE_ON_BLACK);
        row = offset / (2*VIDEO_COLS);
        col = (offset - row * 2 * VIDEO_COLS)/2;

        ++i;
    }
}

void clear_screen() {
    u8* screen = (u8*) VIDEO_ADDR;
    for (int i=0; i<VIDEO_COLS*VIDEO_ROWS; ++i) {
        screen[i*2] = ' ';
        screen[i*2 + 1] = WHITE_ON_BLACK;
    }

    set_cursor_offset(get_screen_offset(0, 0));
}

void main() {
    u8* message = "Successfully loaded kernel!\0";
    print_string(message, 0, VIDEO_ROWS / 2);
}
