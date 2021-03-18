/**
* Name: prey
* Group 6:
* Carina Kær, 201605999
* Christian Thing Knudsen, 201607661
* Daniel Noergbygaard, 201608822
* Lars Lippert Ovesen, 201609678
*/

model prey


species prey parent: generic_species { // Sheep
    rgb color <- #blue;
    float max_energy <- prey_max_energy;
    float max_transfert <- prey_max_transfert;
    float energy_consum <- prey_energy_wandering;
    float proba_reproduce <- prey_proba_reproduce;
    int nb_max_offsprings <- prey_nb_max_offsprings;
    float energy_reproduce <- prey_energy_reproduce;
    image_file my_icon <- image_file("../includes/sheep.png");

    float energy_from_eat {
        float energy_transfert <- 0.0;
        if(my_cell.food > 0) {
            energy_transfert <- min([max_transfert, my_cell.food]);
            my_cell.food <- my_cell.food - energy_transfert;
        }             
        return energy_transfert;
    }
    
    vegetation_cell choose_cell { // Chooses the cell within one which is most juicy within one.
    	vegetation_cell danger_zone <- (shuffle(my_cell.neighbors1) first_with (!(empty (predator inside (each)))));
    	if (danger_zone != nil) { // Returns nil if no predator is near, otherwise it returns a cell
    		energy_consum <- prey_energy_flee;
    		return shuffle(my_cell.neighbors3-my_cell.neighbors2) farthest_to danger_zone; // Flee
    	}
    	
    	vegetation_cell my_cell_vision_pred <- ((my_cell.neighbors3) first_with (!(empty (predator inside (each)))));
    	if (my_cell_vision_pred != nil) {
    		energy_consum <- prey_energy_wandering;
    		return shuffle(my_cell.neighbors1) farthest_to my_cell_vision_pred; // Walk from predator
    	}
    	
    	if (energy > energy_reproduce) {
    		vegetation_cell my_cell_reproduce <- (shuffle(my_cell.neighbors1) first_with (!(empty (prey inside (each)))));
    		if (my_cell_reproduce != nil) {
    			energy_consum <- prey_energy_grazing;
    			return my_cell; // Stand still
    		}
    		
    		vegetation_cell my_cell_vision_prey <- ((my_cell.neighbors3) first_with (!(empty (prey inside (each)))));
    		if (my_cell_vision_prey != nil) {
    			energy_consum <- prey_energy_wandering;
    			return shuffle(my_cell.neighbors1) closest_to my_cell_vision_prey; // Walk to friend
    		}
    	}
    	
    	vegetation_cell best_neighbor <- (shuffle(my_cell.neighbors1) with_max_of (each.food)); // Most juicy neighbor   	
    	
    	if best_neighbor.food>my_cell.food { // Walk one cell
    		energy_consum <- prey_energy_wandering;
    		return best_neighbor;
    	}
    	else { // Stay
    		energy_consum <- prey_energy_grazing;
    		return my_cell;
    	}
    }
    
    reflex reproduce when: (energy >= energy_reproduce) and (flip(proba_reproduce)) and (shuffle(my_cell.neighbors1) first_with (!(empty (prey inside (each))))) { 
        int nb_offsprings <- rnd(1, nb_max_offsprings);
        create species(self) number: nb_offsprings {
            my_cell <- myself.my_cell;
            location <- my_cell.location;
            energy <- myself.energy / nb_offsprings;
        }

        energy <- energy-energy_reproduce; // Energy consumption for reproduction
    }
}
