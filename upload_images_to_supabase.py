"""
One-time (re-runnable) uploader: pushes every file in herb_images/ (produced
by extract_images.py) to the Supabase Storage bucket configured in .env, so
the images don't need to live in git. Safe to re-run -- already-uploaded
files (same name already in the bucket) are skipped.
"""
import mimetypes
import os

from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

IMAGES_DIR = "herb_images"
BUCKET = os.environ["SUPABASE_BUCKET"]


def _list_all(bucket, page_size=1000):
    """bucket.list() caps out below our file count regardless of requested
    limit (observed ceiling around 1000-1500), so page with offset."""
    names, offset = [], 0
    while True:
        page = bucket.list(options={"limit": page_size, "offset": offset})
        names.extend(entry["name"] for entry in page)
        if len(page) < page_size:
            return names
        offset += page_size


def main():
    client = create_client(
        os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    )
    bucket = client.storage.from_(BUCKET)

    existing = set(_list_all(bucket))
    print(f"{len(existing)} file(s) already in bucket '{BUCKET}'.")

    local_files = sorted(os.listdir(IMAGES_DIR))
    to_upload = [f for f in local_files if f not in existing]
    print(f"{len(local_files)} local file(s), {len(to_upload)} to upload.")

    uploaded, failed = 0, []
    for i, filename in enumerate(to_upload, 1):
        path = os.path.join(IMAGES_DIR, filename)
        content_type = mimetypes.guess_type(filename)[0] or "application/octet-stream"
        with open(path, "rb") as f:
            try:
                bucket.upload(
                    filename, f, file_options={"content-type": content_type}
                )
                uploaded += 1
            except Exception as e:
                failed.append((filename, str(e)))
        if i % 100 == 0 or i == len(to_upload):
            print(f"  {i}/{len(to_upload)} processed...")

    print(f"\nDone. Uploaded {uploaded}, failed {len(failed)}.")
    if failed:
        print("Failures:")
        for name, err in failed[:20]:
            print(f"  {name}: {err}")


if __name__ == "__main__":
    main()
