module graphics.gui.action.Action;

import d2d;
import graphics;
import logic;

/**
 * A class which denotes an action
 */
abstract class Action {

    string name; ///The name of this action
    Display container; ///The display containing this action
    ButtonMenu menu; ///The menu containing this action

    /**
     * Constructs a new action with the given name
     * given display container and the buttonmenu 
     * in which the action is stored 
     */
    this(string name, Display container, ButtonMenu menu) {
        this.name = name;
        this.container = container;
        this.menu = menu;
    }

    /**
     * Performs the action
     */
    abstract void perform();

    /**
     * Performs the action from a query
     * Uses whatever the query resulted in, 
     * either a coordinate or a string
     * Not all actions use queries, so
     * it is an optional override
     */
    void performAfterQuery(Coordinate target, string str="") {

    }

    /**
     * Sets a query to the contained display
     * For internal use only
     */
    void setQuery(Query query) {
        (cast(GameActivity)this.container.activity).query = query;
    }

    /**
     * Causes the action performed to disable the origin
     * In other words, the action consumes an action of the origin
     */
    void disableOrigin() {
        if(this.menu.origin !is null) {
            this.menu.origin.isActive = false;
        }
        if(cast(City)this.menu.origin) {
            this.menu.configuration = ActionMenu.cityDisabledMenu;
        }
    }

}