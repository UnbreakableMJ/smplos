#ifndef _ST_HB_H
#define _ST_HB_H

#include <harfbuzz/hb.h>
#include <harfbuzz/hb-ft.h>

struct wld_font;

typedef struct {
	hb_buffer_t *buffer;
	hb_glyph_info_t *glyphs;
	hb_glyph_position_t *positions;
	unsigned int count;
} HbTransformData;

void hbcreatebuffer(void);
void hbdestroybuffer(void);
void hbunloadfonts(void);
void hbtransform(HbTransformData *, struct wld_font *, const Glyph *, int, int);

#endif /* _ST_HB_H */
