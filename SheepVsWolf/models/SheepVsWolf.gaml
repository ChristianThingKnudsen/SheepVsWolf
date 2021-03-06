model prey_predator

global {
    int nb_preys_init <- 200; // 200
    int nb_predators_init <- 20; // 20
    
    // Prey values
    float prey_max_energy <- 1.0;
    float prey_max_transfert <- 0.1;
    float prey_energy_wandering <- 0.2; //0.2
    float prey_energy_flee <- 0.25;
    float prey_energy_grazing <- 0.01; //0.01 
    float prey_proba_reproduce <- 0.01; 
    int prey_nb_max_offsprings <- 5;
    float prey_energy_reproduce <- 0.5;
    
    // Predator values
    float predator_max_energy <- 1.0;
    float predator_energy_transfert <- 0.5;
    float predator_energy_wandering <- 0.2; //0.2
    float predator_energy_sprint <- 0.25; //0.25
    float predator_energy_standing <- 0.01;
    float predator_proba_reproduce <- 0.01; //0.01
    int predator_nb_max_offsprings <- 3;
    float predator_energy_reproduce <- 0.5;
    
    file map_init <- image_file("../includes/raster_map.png");
    int nb_preys -> {length(prey)};
    int nb_predators -> {length(predator)};

    init {
        create prey number: nb_preys_init;
        create predator number: nb_predators_init;
        ask vegetation_cell {
    		color <- rgb (map_init at {grid_x,grid_y}) ;
    		food <- 1 - (((color as list) at 0) / 255) ;
    		food_prod <- food / 100 ; 
    	}
    }
    
    reflex stop_simulation when: (nb_preys = 0) or (nb_predators = 0) {
        do pause ;
    } 
    
    reflex save_result when: (nb_preys > 0) and (nb_predators > 0){
    save ("cycle: "+ cycle + "; nbPreys: " + nb_preys
      + "; minEnergyPreys: " + (prey min_of each.energy)
      + "; maxSizePreys: " + (prey max_of each.energy) 
      + "; nbPredators: " + nb_predators           
      + "; minEnergyPredators: " + (predator min_of each.energy)          
      + "; maxSizePredators: " + (predator max_of each.energy)) 
      to: "results.txt" type: "text" ;
}
}

species generic_species {
    float size <- 1.0;
    rgb color;
    float max_energy;
    float max_transfert;
    float energy_consum;
    float proba_reproduce;
    int nb_max_offsprings;
    float energy_reproduce;
    image_file my_icon;
    vegetation_cell my_cell <- one_of(vegetation_cell);
    float energy <- rnd(max_energy) update: energy - energy_consum max: max_energy;

    init {
        location <- my_cell.location;
    }

    reflex basic_move {
        my_cell <- choose_cell();
        location <- my_cell.location;
    }
    
    vegetation_cell choose_cell {
    	return nil;
    } 

    reflex eat {
        energy <- energy + energy_from_eat();        
    }

    reflex die when: energy <= 0 {
        do die;
    }

    reflex reproduce { 
        return nil;
        
    }

    float energy_from_eat {
        return 0.0;
    }

    aspect base {
        draw circle(size) color: color;
    }

    aspect icon {
        draw my_icon size: 2 * size;
    }

    aspect info {
        draw square(size) color: color;
        draw string(energy with_precision 2) size: 3 color: #black;
    }
}

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

grid vegetation_cell width: 50 height: 50 neighbors: 8 {
    float max_food <- 1.0;
    float food_prod <- rnd(0.01);
    float food <- rnd(1.0) max: max_food update: food + food_prod;
    rgb color <- rgb(int(255 * (1 - food)), 255, int(255 * (1 - food))) update: rgb(int(255 * (1 - food)), 255, int(255 * (1 - food)));
    list<vegetation_cell> neighbors1 <- (self neighbors_at 1);
    list<vegetation_cell> neighbors2 <- (self neighbors_at 2);
    list<vegetation_cell> neighbors3 <- (self neighbors_at 3);
    list<vegetation_cell> neighbors4 <- (self neighbors_at 4);
    list<vegetation_cell> neighbors6 <- (self neighbors_at 6);
    
}

experiment prey_predator type: gui {
    parameter "Initial number of preys: " var: nb_preys_init min: 0 max: 1000 category: "Prey";
    parameter "Prey max energy: " var: prey_max_energy category: "Prey";
    parameter "Prey max transfert: " var: prey_max_transfert category: "Prey";
    parameter "Prey energy consumption: " var: prey_energy_wandering category: "Prey";
    parameter "Initial number of predators: " var: nb_predators_init min: 0 max: 200 category: "Predator";
    parameter "Predator max energy: " var: predator_max_energy category: "Predator";
    parameter "Predator energy transfert: " var: predator_energy_transfert category: "Predator";
    parameter "Predator energy consumption: " var: predator_energy_wandering category: "Predator";
    parameter 'Prey probability reproduce: ' var: prey_proba_reproduce category: 'Prey';
    parameter 'Prey nb max offsprings: ' var: prey_nb_max_offsprings category: 'Prey';
    parameter 'Prey energy reproduce: ' var: prey_energy_reproduce category: 'Prey';
    parameter 'Predator probability reproduce: ' var: predator_proba_reproduce category: 'Predator';
    parameter 'Predator nb max offsprings: ' var: predator_nb_max_offsprings category: 'Predator';
    parameter 'Predator energy reproduce: ' var: predator_energy_reproduce category: 'Predator';

    output {
        display main_display {
            grid vegetation_cell lines: #black;
            species prey aspect: icon;
            species predator aspect: icon;
        }

        display info_display {
            grid vegetation_cell lines: #black;
            species prey aspect: info;
            species predator aspect: info;
        }

        display Population_information refresh: every(5#cycles) {
            chart "Species evolution" type: series size: {1,0.5} position: {0, 0} {
                data "number_of_preys" value: nb_preys color: #blue;
                data "number_of_predator" value: nb_predators color: #red;
            }
            chart "Prey Energy Distribution" type: histogram background: #lightgray size: {0.5,0.5} position: {0, 0.5} {
                data "]0;0.25]" value: prey count (each.energy <= 0.25) color:#blue;
                data "]0.25;0.5]" value: prey count ((each.energy > 0.25) and (each.energy <= 0.5)) color:#blue;
                data "]0.5;0.75]" value: prey count ((each.energy > 0.5) and (each.energy <= 0.75)) color:#blue;
                data "]0.75;1]" value: prey count (each.energy > 0.75) color:#blue;
            }
            chart "Predator Energy Distribution" type: histogram background: #lightgray size: {0.5,0.5} position: {0.5, 0.5} {
                data "]0;0.25]" value: predator count (each.energy <= 0.25) color: #red;
                data "]0.25;0.5]" value: predator count ((each.energy > 0.25) and (each.energy <= 0.5)) color: #red;
                data "]0.5;0.75]" value: predator count ((each.energy > 0.5) and (each.energy <= 0.75)) color: #red;
                data "]0.75;1]" value: predator count (each.energy > 0.75) color: #red;
            }
        }

        monitor "Number of preys" value: nb_preys;
        monitor "Number of predators" value: nb_predators;
    }
}