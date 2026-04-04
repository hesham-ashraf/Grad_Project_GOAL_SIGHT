import os
from SoccerNet.Downloader import SoccerNetDownloader

def download_soccernet_data(local_dir="./data/soccernet"):
    os.makedirs(local_dir, exist_ok=True)

    dl = SoccerNetDownloader(LocalDirectory=local_dir)

    dl.downloadGames(
        files=["Labels-v2.json"],
        split=["train", "valid", "test"]
    )

    dl.downloadGames(
        files=["1_ResNET_TF2_PCA512.npy", "2_ResNET_TF2_PCA512.npy"],
        split=["train", "valid", "test"]
    )

    print(f"Done  Saved to: {os.path.abspath(local_dir)}")

if __name__ == "__main__":
    download_soccernet_data()