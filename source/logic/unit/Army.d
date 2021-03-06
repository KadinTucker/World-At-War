module logic.unit.Army;

import logic;

import std.math;

//Below are statistics of each unit type
immutable int infantryHP = 5;
immutable int tankHP = 30;
immutable int artilleryHP = 15;

immutable int infantryAttack = 3;
immutable int tankAttack = 12;
immutable int arilleryAttack = 13;

immutable int tankSiege = 9;

immutable int infantryDefense = 5;
immutable int tankDefense = 17;
immutable int artilleryDefense = 18;

immutable int infantryMovement = 5;
immutable int inverseInfantryProportion = 5; //Reciprocal of how much infantry are counted in movement calculation
immutable int tankMovement = 7;
immutable int artilleryMovement = 4;

//The movement point cost to capture a territory
//divided by the army's hp
immutable int territoryCaptureCost = 200;

/**
 * A land army unit
 */
class Army : Unit {

    int movementPoints; ///The amount of moves this army can take this turn

    /**
     * Constructs a new land army
     * Units are in order: infantry, tanks, artillery
     */
    this(Player owner, Coordinate location, World world) {
        super(owner, location, world);
        this.troops = [0, 0, 0];
        this.wounds = [0, 0, 0];
        this.attacked = [false, false];
        this.movementPoints = this.moves;
    }

    /**
     * Returns the number of moves this army can make per turn
     * Averages move amounts of each unit; infantry are counted 1/5 as much
     */
    @property int moves() {
        if(this.isEmpty()) {
            return 0;
        }
        return cast(int)round((cast(double)infantryMovement * (cast(double)this.troops[0] / cast(double)inverseInfantryProportion) 
                + cast(double)tankMovement * cast(double)this.troops[1] 
                + cast(double)artilleryMovement * cast(double)this.troops[2])
                / (cast(double)this.troops[0] / cast(double)inverseInfantryProportion 
                + cast(double)this.troops[1] + cast(double)this.troops[2]));
    }

    /**
     * Runs unit mobilize, but captures the territory 
     * onto which it is mobilized
     */
    override void mobilize() {
        super.mobilize();
        if(this.world.getTileAt(this.location).owner !is null) {
            this.world.getTileAt(this.location).owner.territory -= 1;
        }
        this.world.getTileAt(this.location).owner = this.owner;
        this.world.getTileAt(this.location).owner.territory += 1;
        this.movementPoints = 0;
    }
    
    /**
     * Moves the unit
     * Can only move onto empty land
     */
    override void move(Coordinate target) {
        if(this.world.getTileAt(target).terrain == Terrain.LAND) {
            if(this.world.getTileAt(target).element is null) {
                this.world.getTileAt(this.location).element = null;
                this.location = target;
                this.world.getTileAt(this.location).element = this;
                this.movementPoints -= 1;
                this.captureTerritory(this.world.getTileAt(target));
                return;
            } else if(cast(City)this.world.getTileAt(target).element) {
                this.addTo((cast(City)this.world.getTileAt(target).element).garrison);
                this.getDestroyed();
                return;
            }
        } 
        if(cast(Unit)this.world.getTileAt(target).element) {
            this.addTo(cast(Unit)this.world.getTileAt(target).element);
            this.getDestroyed();
        }
    }

    /**
     * Takes damage
     * Tanks take damage before other units, then infantry,
     * then last artillery
     */
    override void takeDamage(int damage, Unit attacker) {
        while(damage > 0 && !this.isEmpty()) {
            if(this.troops[1] > 0) {
                this.wounds[1] += 1;
            } else if(this.troops[0] > 0) {
                this.wounds[0] += 1;
            } else {
                this.wounds[2] += 1;
            }
            if(this.wounds[0] >= infantryHP) {
                this.troops[0] -= 1;
                this.wounds[0] -= infantryHP;
            }
            if(this.wounds[1] >= tankHP) {
                this.troops[1] -= 1;
                this.wounds[1] -= tankHP;
            }
            if(this.wounds[2] >= artilleryHP) {
                this.troops[2] -= 1;
                this.wounds[2] -= artilleryHP;
            }
            damage -= 1;
        }
        if(this.isEmpty()) {
            this.getDestroyed();
        }
    }

    /**
     * Attacks the target location
     * Index of zero means tanks and infantry,
     * One means artillery
     */
    override void attack(TileElement target, int index) {
        super.attack(target, index);
        if(index == 0) {
            target.takeDamage(infantryAttack * this.troops[0], this);
            if(cast(City)target) {
                target.takeDamage(tankSiege * this.troops[1], this);
            } else {
                target.takeDamage(tankAttack * this.troops[1], this);
            }
        } else if(index == 1) {
            target.takeDamage(arilleryAttack * this.troops[2], this);
        }
    }

    /**
     * Armies perform no actions to defend their cities
     */
    override void garrisonAction(int damage, Unit attacker, City toDefend) {
        
    }

    /**
     * Returns the value of each troop to a garrison
     */
    override int garrisonValue() {
        return this.troops[0] * infantryDefense + this.troops[1] * tankDefense;
    }

    /**
     * Adds this unit to another target unit
     * The target unit must be an army
     */
    override void addTo(Unit unit) {
        if(cast(Army)unit) {
            unit.troops[0] += this.troops[0];
            unit.troops[1] += this.troops[1];
            unit.troops[2] += this.troops[2];
            this.disable();
            unit.disable();
        } else if(cast(Fleet)unit) {
            this.addTo((cast(Fleet)unit).embarked);
        }
    }

    /**
     * Resolves the turn by refreshing the attacks of the units
     * And the army's movement points
     */
    override void resolveTurn() {
        super.resolveTurn();
        this.movementPoints = this.moves;
    }

    /**
     * Disables the army
     */
    override void disable() {
        super.disable();
        this.movementPoints = 0;
    }

    /**
     * Runs when the army captures a territory
     * Reduces movement points based on the hitpoints of the army
     */
    private void captureTerritory(Tile tile) {
        if(tile !is null && tile.owner != this.owner) {
            this.movementPoints -= territoryCaptureCost / 
                    (this.troops[0] * infantryHP + this.troops[1] * tankHP + this.troops[2] * artilleryHP);
            if(this.movementPoints < 0) {
                this.movementPoints = 0;
            }
            if(tile.owner !is null) {
                tile.owner.territory -= 1;
            }
            tile.owner = this.owner;
            this.owner.territory += 1;
        }
    }

}