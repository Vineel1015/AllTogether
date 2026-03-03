import scrapy
import json
from bs4 import BeautifulSoup

class RecipeSpider(scrapy.Spider):
    name = 'recipe_spider'

    def __init__(self, url=None, *args, **kwargs):
        super(RecipeSpider, self).__init__(*args, **kwargs)
        self.start_urls = [url] if url else []

    def parse(self, response):
        # Attempt to find JSON-LD first (most reliable for recipes)
        json_ld = response.css('script[type="application/ld+json"]::text').getall()
        recipe_data = None
        
        for ld in json_ld:
            try:
                data = json.loads(ld)
                # JSON-LD can be a single object or a list
                if isinstance(data, list):
                    for item in data:
                        if item.get('@type') == 'Recipe' or 'Recipe' in item.get('@type', []):
                            recipe_data = item
                            break
                elif data.get('@type') == 'Recipe' or 'Recipe' in data.get('@type', []):
                    recipe_data = data
                
                if recipe_data:
                    break
            except (json.JSONDecodeError, TypeError):
                continue

        if recipe_data:
            yield {
                'title': recipe_data.get('name'),
                'ingredients': recipe_data.get('recipeIngredient', []),
                'steps': self.parse_steps(recipe_data.get('recipeInstructions')),
                'source_name': response.css('meta[property="og:site_name"]::attr(content)').get() or response.url.split('/')[2],
                'prep_minutes': self.parse_duration(recipe_data.get('totalTime')),
                'calories': self.extract_calories(recipe_data.get('nutrition'))
            }
        else:
            # Fallback to BeautifulSoup/CSS Selectors for non-structured sites
            yield self.parse_fallback(response)

    def parse_steps(self, instructions):
        if not instructions:
            return []
        if isinstance(instructions, str):
            return [instructions]
        
        steps = []
        for instr in instructions:
            if isinstance(instr, dict):
                steps.append(instr.get('text') or instr.get('name'))
            else:
                steps.append(str(instr))
        return steps

    def parse_duration(self, duration_str):
        if not duration_str or not isinstance(duration_str, str):
            return 0
        # Basic ISO 8601 duration parser (e.g., PT1H30M)
        import re
        hours = re.search(r'(\d+)H', duration_str)
        minutes = re.search(r'(\d+)M', duration_str)
        total = 0
        if hours: total += int(hours.group(1)) * 60
        if minutes: total += int(minutes.group(1))
        return total

    def extract_calories(self, nutrition):
        if not nutrition: return 0
        if isinstance(nutrition, dict):
            cal = nutrition.get('calories', '0')
            if isinstance(cal, str):
                return int(''.join(filter(str.isdigit, cal)) or 0)
            return int(cal)
        return 0

    def parse_fallback(self, response):
        # Very generic fallback
        return {
            'title': response.css('h1::text').get(),
            'ingredients': response.css('li:contains("ingredient")::text, .ingredients li::text').getall(),
            'steps': response.css('.instructions li::text, .steps li::text, .recipe-steps li::text').getall(),
            'source_name': response.url.split('/')[2]
        }
