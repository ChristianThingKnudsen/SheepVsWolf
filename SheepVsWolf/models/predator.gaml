/**
* Name: predator
* Group 6:
* Carina Kær, 201605999
* Christian Thing Knudsen, 201607661
* Daniel Noergbygaard, 201608822
* Lars Lippert Ovesen, 201609678
*/


model predator

species predator parent: generic_species { // Wolf
    rgb color <- #red;
    float max_energy <- predator_max_energy;
    float energy_transfert <- predator_energy_transfert;
    float energy_consum <- predator_energy_wandering;
    float proba_reproduce <- predator_proba_reproduce;
    int nb_max_offsprings <- predator_nb_max_offsprings;
    float energy_reproduce <- predator_energy_reproduce;
    image_file my_icon <- image_file("../includes/wolf.png");
    
    vegetation_cell choose_cell {
        vegetation_cell my_cell_tmp <- shuffle(my_cell.neighbors2) first_with (!(empty (prey inside (each)))); 
	    if my_cell_tmp != nil { // Sprinting
	    	energy_consum <- predator_energy_sprint;
	        return my_cell_tmp; // Sprint to prey
	    } else { // Wandering
	    	vegetation_cell my_cell_smell;
	    	if (energy >= energy_reproduce) {
	    		if ((my_cell.neighbors1) first_with (!(empty (predator inside (each)))) != nil) {
	    			energy_consum <- predator_energy_standing;
	    			return my_cell; // Stand still
	    		}
	    		
	    		my_cell_smell <- (my_cell.neighbors6) first_with (!(empty (predator inside (each)))); // Setting smell to partner
	    	}
	    	
	    	if my_cell_smell != nil{   
	    		energy_consum <- predator_energy_wandering;		
	    		return my_cell.neighbors1 closest_to my_cell_smell; // Find partner
	    	} else {
	    		my_cell_smell <- (my_cell.neighbors6) first_with (!(empty (prey inside (each)))); // Setting smell to prey
	    	} 
	    	
	    	if my_cell_smell != nil {    	
	    		energy_consum <- predator_energy_wandering;	
	    		return my_cell.neighbors1 closest_to my_cell_smell; // Find prey
	    	}
	    	
	    	vegetation_cell my_cell_vision <- ((my_cell.neighbors2) with_max_of (each.food));
	    	if my_cell_vision.food > my_cell.food { // Walk one cell
	    		energy_consum <- predator_energy_wandering;
	    		if my_cell.neighbors1 contains my_cell_vision {
	    			return my_cell_vision; // Walk to juicy grass
	    		}    			
	    		return shuffle(my_cell.neighbors1) closest_to my_cell_vision; // Find juicy grass
	    	} else {    		
	    		if my_cell.food = my_cell_vision.food{
	    			energy_consum <- predator_energy_wandering;
	        		return one_of (my_cell.neighbors1); // Wander around
	    		} 
	    		energy_consum <- predator_energy_standing;
	    		return my_cell; // Stay at juicy grass    	
	    	} 
	    } 
    }

    float energy_from_eat {
        list<prey> reachable_preys <- prey inside (my_cell);
        if(! empty(reachable_preys)) {
            ask one_of (reachable_preys) {
                do die;
            }
            return energy_transfert;
        }
        return 0.0;
    }
    
    reflex reproduce when: (energy >= energy_reproduce) and (flip(proba_reproduce)) and (my_cell.neighbors1 first_with (!(empty (predator inside (each))))) { 
        int nb_offsprings <- rnd(1, nb_max_offsprings);
        create species(self) number: nb_offsprings {
            my_cell <- myself.my_cell;
            location <- my_cell.location;
            energy <- myself.energy / nb_offsprings;
        }

        energy <- energy-energy_reproduce; // Energy consumption for reproduction
    }
}