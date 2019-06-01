
class EndUse
    attr_accessor :heating, :cooling, :interior_lighting, :exterior_lighting, :interior_equipment, :exterior_equipment, :fans, :pumps, :heat_rejection, :humidification, :heat_recovery, :water_systems, :refrigeration, :generators

    def initialize(hash={})
        hash.delete_if {|k, v| v.nil?}
        hash = defaults.merge(hash)
        
        @heating = hash[:heating]
        @cooling = hash[:cooling]
        @interior_lighting = hash[:interior_lighting]
        @exterior_lighting = hash[:exterior_lighting]
        @interior_equipment = hash[:interior_equipment]
        @exterior_equipment = hash[:exterior_equipment]
        @fans = hash[:fans]
        @pumps = hash[:pumps]
        @heat_rejection = hash[:heat_rejection]
        @humidification = hash[:humidification]
        @heat_recovery = hash[:heat_recovery]
        @water_systems = hash[:water_systems]
        @refrigeration = hash[:refrigeration]
        @generators = hash[:generators]
    end

    def defaults
        hash = {}

        hash[:heating] = 0
        hash[:cooling] = 0
        hash[:interior_lighting] = 0
        hash[:exterior_lighting] = 0
        hash[:interior_equipment] = 0
        hash[:exterior_equipment] = 0 
        hash[:fans] = 0
        hash[:pumps] = 0
        hash[:heat_rejection] = 0
        hash[:humidification] = 0
        hash[:heat_recovery] = 0
        hash[:water_systems] = 0
        hash[:refrigeration] = 0 
        hash[:generators] = 0
        
        return hash
    end

    
    def to_hash
        result = {}

        result[:heating] = @heating
        result[:cooling] = @cooling
        result[:interior_lighting] = @interior_lighting
        result[:exterior_lighting] = @exterior_lighting
        result[:interior_equipment] = @interior_equipment
        result[:exterior_equipment] = @exterior_equipment
        result[:fans] = @fans
        result[:pumps] = @pumps
        result[:heat_rejection] = @heat_rejection
        result[:humidification] = @humidification 
        result[:heat_recovery] = @heat_recovery 
        result[:water_systems] = @water_systems 
        result[:refrigeration] = @refrigeration
        result[:generators] = @generators 

        return result

    end
    
    def merge_end_use!(new_end_use)
    
        @heating += new_end_use.heating 
        @cooling += new_end_use.cooling 
        @interior_lighting += new_end_use.interior_lighting 
        @exterior_lighting += new_end_use.exterior_lighting 
        @interior_equipment += new_end_use.interior_equipment 
        @exterior_equipment += new_end_use.exterior_equipment 
        @fans += new_end_use.fans 
        @pumps += new_end_use.pumps
        @heat_rejection += new_end_use.heat_rejection
        @humidification += new_end_use.humidification 
        @heat_recovery += new_end_use.heat_recovery
        @water_systems += new_end_use.water_systems 
        @refrigeration += new_end_use.refrigeration
        @generators += new_end_use.generators
 
        return self
    end

end

#test