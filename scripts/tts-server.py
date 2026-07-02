#!/usr/bin/env python3
import os
import tempfile
import asyncio
from concurrent.futures import ThreadPoolExecutor

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from TTS.api import TTS
import uvicorn
import torch

PORT = 5002
DEFAULT_LANGUAGE = "de"

print(f"CUDA: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")

print("Ładowanie XTTS v2...")
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2", gpu=True)
print("Model gotowy!")

executor = ThreadPoolExecutor(max_workers=1)

app = FastAPI(title="XTTS v2 Server")

class TTSRequest(BaseModel):
    text: str
    language: str = DEFAULT_LANGUAGE
    speaker_wav: str | None = None

@app.get("/health")
def health():
    return {"status": "ok", "cuda": torch.cuda.is_available()}

def _generate(text, language, speaker_wav, output_path):
    kwargs = {"text": text, "language": language, "file_path": output_path}
    if speaker_wav and os.path.exists(speaker_wav):
        kwargs["speaker_wav"] = speaker_wav
    tts.tts_to_file(**kwargs)
    return output_path

@app.post("/tts")
async def tts_simple(req: TTSRequest):
    if not req.text or len(req.text.strip()) == 0:
        raise HTTPException(400, "Pusty tekst")
    try:
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            output_path = tmp.name
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(executor, _generate, req.text.strip(), req.language, req.speaker_wav, output_path)
        return {"file": output_path, "play": f"pw-play {output_path}", "format": "wav"}
    except Exception as e:
        raise HTTPException(500, str(e))

if __name__ == "__main__":
    print(f"Serwer: http://0.0.0.0:{PORT}")
    uvicorn.run(app, host="0.0.0.0", port=PORT, log_level="info")
