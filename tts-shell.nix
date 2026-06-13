{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    python311
    libsndfile
    ffmpeg
  ];

  shellHook = ''
    echo "=== XTTS v2 Shell ==="
    
    # Twoje działające CUDA z llama.cpp
    export LD_LIBRARY_PATH="/run/opengl-driver/lib:$HOME/.lmstudio/extensions/backends/vendor/linux-llama-cuda12-vendor-v1:$LD_LIBRARY_PATH"
    
    # Venv w Twoim home, nie w /root
    export VENV_DIR="$HOME/.venv-tts-xtts"
    
    if [ ! -d "$VENV_DIR" ]; then
      echo "Tworzenie venv w $VENV_DIR..."
      python3.11 -m venv "$VENV_DIR"
      source "$VENV_DIR/bin/activate"
      
      echo "Instalacja pip przez ensurepip..."
      python -m ensurepip --upgrade
      
      echo "Instalacja pakietów... (to zajmie 10-20 min)"
      pip install --upgrade pip wheel setuptools
      pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu121
      pip install TTS==0.22.0
      pip install fastapi uvicorn soundfile pydantic
    else
      source "$VENV_DIR/bin/activate"
    fi
    
    echo "Sprawdzanie CUDA..."
    python -c "import torch; print(f'PyTorch: {torch.__version__}, CUDA: {torch.cuda.is_available()}, GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"brak\"}')"
    
    export PS1="(tts) \w $ "
  '';
}
