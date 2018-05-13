module graphics.components.Map;

import d2d;
import graphics.CityDisplay;
import logic.player.City;
import logic.world.World;
import logic.world.Tile;

/**
 * A component that displays and handles interation with the world
 */
class Map : Component {

    iRectangle _location; //The location on the screen of the map
    iVector pan; //The offset of the center of the map
    World world; //The world to be drawn by the map
    Texture waterTexture; //The water texture to be drawn
    Texture landTexture; //The land texture
    Texture cityTexture; //The texture for cities on the map

    /**
     * Constructs a new map in the given display, bounded by the given rectangle 
     *      and displaying the given world
     */
    this(Display container, iRectangle location, World world) {
        super(container);
        this.world = world;
        this.pan = new iVector(0, 0);
        this._location = location;
        this.waterTexture = new Texture(loadImage("res/Tile/water.png"), this.container.renderer);
        this.landTexture = new Texture(loadImage("res/Tile/land.png"), this.container.renderer);
        this.cityTexture = new Texture(loadImage("res/City/shenyang.png"), this.container.renderer);
        this.world[4][6].city = new City(Coordinate(4, 7), null, 8);
    }

    /**
     * Returns the location of the map
     */
    override @property iRectangle location() {
        return this._location;
    }

    /**
     * Handles incoming events to the map component
     * Pans the map using the arrow keys
     */
    void handleEvent(SDL_Event event) {
        
    }

    /**
     * Draws the map to the screen
     */
    override void draw() {
        for(int x; x < this.world.length; x++) {
            for(int y; y < this.world[x].length; y++) {
                if(world[x][y].terrain == Terrain.WATER) {
                    this.container.renderer.copy(this.waterTexture, this._location.initialPoint.x + this.pan.x + 50 * x, 
                            this._location.initialPoint.y + this.pan.y + 50 * y);
                } else if(world[x][y].terrain == Terrain.LAND) {
                    this.container.renderer.copy(this.landTexture, this._location.initialPoint.x + this.pan.x + 50 * x, 
                            this._location.initialPoint.y + this.pan.y + 50 * y);
                }
                if(world[x][y].city !is null) {
                    this.container.renderer.copy(generateCityTexture(world[x][y].city, this.container.renderer), 
                            this._location.initialPoint.x + this.pan.x + 50 * x, this._location.initialPoint.y + this.pan.y + 50 * y);
                }
            }
        }
        if(this.container.keyboard.allKeys[SDLK_UP].isPressed) {
            this.pan.y += 14;
        }
        if(this.container.keyboard.allKeys[SDLK_RIGHT].isPressed) {
            this.pan.x -= 14;
        }
        if(this.container.keyboard.allKeys[SDLK_DOWN].isPressed) {
            this.pan.y -= 14;
        }
        if(this.container.keyboard.allKeys[SDLK_LEFT].isPressed) {
            this.pan.x += 14;
        }
    }

}