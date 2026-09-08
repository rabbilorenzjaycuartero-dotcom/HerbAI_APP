"""
Extract herb photos embedded in "HERBAL_DB data_image.xlsx" cells and save
them keyed by row position, so they line up with the `pos` index api_server.py
already uses as each herb's id.

The xlsx is a zip archive. Images live under xl/media/, and which row each
image belongs to is recorded in xl/drawings/drawing1.xml (a <oneCellAnchor>
per image, giving its 0-indexed row) + xl/drawings/_rels/drawing1.xml.rels
(mapping each anchor's r:embed id to its xl/media/imageN.jpg file).

xlsx row N (0-indexed, row 0 = header) == HERBAL_DB CSV row (N-1) ==
the `pos` index used throughout the training/serving pipeline, verified by
cross-checking herb names at several rows against HERBAL_DB - Sheet3.csv.
"""
import os
import zipfile
import xml.etree.ElementTree as ET

XLSX_PATH = "HERBAL_DB_final.xlsx"
OUT_DIR = "herb_images"

NS_XDR = "http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing"
NS_A = "http://schemas.openxmlformats.org/drawingml/2006/main"
NS_R = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
NS_RELS = "http://schemas.openxmlformats.org/package/2006/relationships"


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    z = zipfile.ZipFile(XLSX_PATH)

    drawing = ET.fromstring(z.read("xl/drawings/drawing1.xml"))
    anchors = []
    for anchor in drawing.findall(f"{{{NS_XDR}}}oneCellAnchor"):
        row = int(anchor.find(f"{{{NS_XDR}}}from/{{{NS_XDR}}}row").text)
        blip = anchor.find(f".//{{{NS_A}}}blip")
        rid = blip.get(f"{{{NS_R}}}embed")
        anchors.append((row, rid))

    rels = ET.fromstring(z.read("xl/drawings/_rels/drawing1.xml.rels"))
    rid_to_target = {
        rel.get("Id"): rel.get("Target")
        for rel in rels.findall(f"{{{NS_RELS}}}Relationship")
    }

    written = 0
    for row, rid in anchors:
        target = rid_to_target.get(rid)
        if not target or "media" not in target:
            continue
        media_path = "xl/" + target.replace("../", "")
        data = z.read(media_path)
        pos = row - 1  # header is row 0, so data row 1 -> pos 0
        if pos < 0:
            continue
        ext = os.path.splitext(media_path)[1] or ".jpg"
        out_path = os.path.join(OUT_DIR, f"{pos}{ext}")
        with open(out_path, "wb") as f:
            f.write(data)
        written += 1

    print(f"Wrote {written} images to {OUT_DIR}/")


if __name__ == "__main__":
    main()
