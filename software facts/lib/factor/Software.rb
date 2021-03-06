Facter.add('software') do
  confine :kernel => 'windows'
  setcode do
    require 'win32/registry'

    # Generate empty array to store hashes
    software_list = []

    # Check if reg path exist, return true / false
    def key_exists?(path, scope)
      begin
        Win32::Registry::scope.open(path, ::Win32::Registry::KEY_READ)
        return true
      rescue
        return false
      end
    end

    # Loop through all uninstall keys for 64bit applications.  
    Win32::Registry::HKEY_LOCAL_MACHINE.open('Software\Microsoft\Windows\CurrentVersion\Uninstall') do |reg|
      reg.each_key do |key|
                
        k = reg.open(key)
        
        displayname     = k["DisplayName"] rescue nil
        version         = k["DisplayVersion"] rescue nil      
        uninstallpath   = k["UninstallString"] rescue nil
        systemcomponent = k["SystemComponent"] rescue nil

        if(displayname && uninstallpath)
          unless(systemcomponent == 1)
            unless(displayname.match(/[KB]{2}\d{7}/)) # excludes windows updates
              software_list << {DisplayName: displayname, Version: version }
            end
          end
        end

      end
    end

    # Loop through all uninstall keys for 32bit applications. 
    Win32::Registry::HKEY_LOCAL_MACHINE.open('Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall') do |reg|
      reg.each_key do |key|
          
        k = reg.open(key)

        displayname     = k["DisplayName"] rescue nil
        version         = k["DisplayVersion"] rescue nil
        uninstallpath   = k["UninstallString"] rescue nil
        systemcomponent = k["SystemComponent"] rescue nil

        if(displayname && uninstallpath)
          unless(systemcomponent == 1)
            unless(displayname.match(/[KB]{2}\d{7}/)) # excludes windows updates
              software_list << {DisplayName: displayname, Version: version }
            end 
          end
        end

      end
    end

    # Loop through all uninstall keys for user applications. 
    Win32::Registry::HKEY_USERS.open('\\') do |reg|
      reg.each_key do |sid|
        unless(sid.include?("_Classes"))   
    
          path = "#{sid}\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
          scope = 'HKEY_USERS'
    
          if key_exists?(path, scope)    
            Win32::Registry::scope.open(path) do |userreg|
              userreg.each_key do |key|
                
                k = userreg.open(key)
                
                displayname   = k["DisplayName"] rescue nil
                version       = k["DisplayVersion"] rescue nil
                uninstallpath = k["UninstallString"] rescue nil

                if(displayname && uninstallpath)
                  software_list << {DisplayName: displayname, Version: version }
                end
                
              end
            end
          end

        end
      end  
    end
    software_list
  end
end
