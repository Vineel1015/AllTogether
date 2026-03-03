from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import subprocess
import json
import os

app = FastAPI()

class ScrapeRequest(BaseModel):
    url: str

@app.get("/")
def read_root():
    return {"status": "Recipe Scraper Service is running"}

@app.post("/extract")
async def extract_recipe(request: ScrapeRequest):
    # Run scrapy as a subprocess and capture output
    # In a production environment, you might use ScrapyRT or a task queue like Celery
    try:
        # We'll output to a temp file and read it
        output_file = 'output.json'
        if os.path.exists(output_file):
            os.remove(output_file)

        process = subprocess.run([
            'scrapy', 'runspider', 'recipe_scraper/spiders/recipe_spider.py',
            '-a', f'url={request.url}',
            '-o', output_file
        ], capture_output=True, text=True)

        if not os.path.exists(output_file):
            return {"error": "Could not extract recipe from this URL"}

        with open(output_file, 'r') as f:
            data = json.load(f)
            if not data:
                raise HTTPException(status_code=404, detail="No recipe found")
            return data[0]

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
