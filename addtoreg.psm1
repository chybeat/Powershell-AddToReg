function addToReg{
    param(
    [Parameter(Mandatory)]
        $regData_in
    )
<#
    Funcion para insertar en el registro de Windows un valor o varios valores desde un String

    >> La funcion recibe un objeto del siguiente modo:
    $registry =  @{
        path = "HKEY_CURRENT_USER\Control Panel\Quick Actions\Control Center\Unpinned"
        name = "Microsoft.QuickAction.AllSettings"
        val  = "hex(0)"
        type = "None"
    }

    Path: Es la ruta recortada o no (en la clave raiz del registro)
          junto con la ruta completa de la carpeta del registro

    Name: Es el nombre de la clave que se asignará o cambiará

    Val: El valor como es exportado desde el editor de registro a un archivo.reg

    Type: El tipo de dato que se guardará en la clave
    (string, expandstring, dword, binary, none, multistring, qword, unknown)



    >> Tambien recibe un "string" que puede ser leido directamente desde un archivo de texto o .reg con las siguientes condiciones
     *Usar comillas simples para enviar ya que evitar errores y escapes de comillas dobles
     *Usar los mismos parámetyos y sintaxis que se usa en los ficheros .reg para eliminar, rutas y separación de líneas
     *Para eliminar una ruta se puede usar guión (-) antes de la ruta. Ej: -[HKEY_CURRENT_USER\test_types\binarios]
     *Para eliminar valores de una clave se debe colocar guión (-) despues de igual y debe ser el único parametro

     *Las cadenas de multiples líneas como algunas binarias, se puede conservar del mismo modo que se guardan en un archivo .reg (77 caracteres por línea)
     *Si se lee un archivo .reg se debe pasar todo el texto del archivo de registro de una sola vez, Si se pasa línea por línea a la funcón no gardará la ruta para los valores
     
    '
    [HKEY_CURRENT_USER\test_types\binarios]
    AnInt64=hex(b):ff,ff,ff,ff,ff,ff,ff,7f
    binario=hex:e0
    binario=-
    Dword32=dword:00007e57
    Qword64=hex(b):75,7e,00,00,00,00,00,00

    [HKEY_CURRENT_USER\test_types]
    @=""
    cadenamultiple=hex(7):74,00,65,00,73,00,74,00,00,00,00,00
    cadenaMultipleExpandible=-
    cadenaMultipleExpandible=hex(2):25,00,63,00,61,00,64,00,65,00,6e,00,61,00,45,\
      00,78,00,70,00,6c,00,61,00,6e,00,64,00,69,00,62,00,6c,00,65,00,25,00,00,00
    '

#>
    process{
        #Determinando tipo de datos enviados (Solo se admiten "Hashtable o "String"
        $regData = $regData_in
        switch($regData.GetType().FullName){
            "System.Collections.Hashtable"{break}

            "System.String"{
                $action	= ""
                $path	= ""
                $name	= ""
                $value	= ""
                $line	= ""
                $type	= ""
                $continueOnNextLine = $false
                $lines = $regData -Split ("`r`n")

                ForEach ($line in $lines){
                    #Si es una línea vacía o empieza con ";" (comentario) se debe omitir al igual que si es la primera linea de un archivo.reg
                    if (($line.trim() -eq "") -or ($line.Substring(0,1) -eq ";") -or ($line.StartsWith("Windows Registry Editor "))){continue}

                    $action = "add"

                    #determinando si es una ruta o clave
                    if(($line.StartsWith("[")) -or ($line.StartsWith("-["))){
                        $path = $line -replace '\[', ""
                        $path = $path -replace ']', ""
                        if($path.StartsWith("-")){
                            $path = $path.Substring(1)
                            $action = "del"
                        }
                    }else{
                        if(!$continueOnNextLine){
                            $name=$line.split("=")[0]
                            $value=$line.split("=")[1]
                            
                            #deterimnando el nombre de la clave en caso de ser el valor predeterminado de la clave
                            if ($name -eq "@"){
                                $name = '(default)'
                            }
                            if($value -eq "-"){
                                $action = "del"
                            }
                        }
                    }

                    # Si no es para eliminar o es una ruta
                    if(!($action -eq "del") -or !($line.Substring(0,1) -eq "[")){

                        #determinando el tipo de valor. Comparativa:
                        # (vacio) = String
                        # hex:    = Binary
                        # dword:  = DWord
                        # hex(b)  = Qword
                        # hex(7): = multistring
                        # hex(2): = ExpandString
                        # hex(0): = None
                        if($continueOnNextLine){
                            $value = $value.trim("\") + $line.trim()
                        }elseif($value.StartsWith("hex:")){
                            $type = "Binary"
                            $continueOnNextLine = $value.EndsWith("\")

                        }elseif($value.StartsWith("dword:")){
                            $type = "DWord"
                            $continueOnNextLine = $false

                        }elseif($value.StartsWith("hex(b):")){
                            $type = "QWord"
                            $continueOnNextLine = $value.EndsWith("\")

                        }elseif($value.StartsWith("hex(7):")){
                            $type = "MultiString"
                            $continueOnNextLine = $value.EndsWith("\")

                        }elseif($value.StartsWith("hex(2):")){
                            $type = "ExpandString"
                            $continueOnNextLine = $value.EndsWith("\")

                        }elseif($value.StartsWith("hex(0):")){
                            $type = "None"
                            $continueOnNextLine = $value.EndsWith("\")

                        }else{
                            $type = "String"
                            $continueOnNextLine = $false

                        }
                        if($value.EndsWith("\")){
                            continue
                        }else{
                            $continueOnNextLine = $false
                        }

                    }
                    if(($line.Substring(0,1) -eq "[")){
                        $type = "Path"
                        $value = $line
                    }

                    if(($action -eq "del")){
                        $type = "del"
                        $value = $line
                    }

                    addToReg(@{
                        path = [string]$path
                        name = [string]$name
                        val  = [string]$value
                        type = [string]$type
                    })
                } # Fin de procesamiento de línea 

                #Fin de proceso si es un string
                #Al ser un String no se necesita realizar ninguna acción posterior. Al detectar un string 
                #la funcion prepara el texto y ejecuta cada línea de nuevo en la misma función de forma recursiva. Por eso "exit"

                exit
            }
            default {
                "`"$regData_in`" No es un 'Hashtable' o 'un string'"
                exit
            }
        }


        #PROCESAMIENTO DE HASHTABLE

        #Optimizar Path
        $regData.path  = $regData.path.Replace("registry::","")
        $regData.path  = $regData.path.Replace("Registry::","")
        $firstSlice = $regData.path.Split("\")[0]

        $newRoot = switch ($firstSlice.toUpper()){
            "HKEY_CLASSES_ROOT" {"HKCR"; break}
            "HKEY_CURRENT_USER" {"HKCU"; break}
            "HKEY_LOCAL_MACHINE" {"HKLM"; break}
            "HKEY_USERS" {"HKU"; break}
            "HKEY_CURRENT_CONFIG" {"HKCC"; break}
            "HKCR" {"HKCR"; break}
            "HKCU" {"HKCU"; break}
            "HKLM" {"HKLM"; break}
            "HKU" {"HKU"; break}
            "HKCC" {"HKCC"; break}
            default {
                "`"$firstSlice`" No es una clave válida"; exit
            }
        }
        $regData.path = "Registry::" + $regData.path.replace("$firstSlice\","$newRoot\")

        #Eliminar del registro
        if($regData.type -eq "del"){
            if(!(Test-Path $regData.Path)){
                return
            }
            if($regData.name -eq ""){
                #Si no hay name se trata de una ruta completa de registro a eliminar
                Remove-Item $regData.path -Recurse -Force
            }else{
                #Eliminando un valor en el registro
                Remove-ItemProperty -ErrorAction Ignore -Path $regData.path -Name $regData.name.Trim("`"") -Force 
            }
            return
        }

        #Si el type es path se forza la creación
        if(($regData.type.toLower()) -eq "path"){
            #Write-Output "Es una ruta. se debe verificar que existe o no para crearla"
            if(Test-Path $regData.Path){
                #Write-Output "La ruta exite, no se debe hacer nada"
                continue
            }else{
                #Write-Host "Crear la ruta " ($regData.Path)
                New-Item -Path $regData.Path -force | out-null
            }
            #Termina el proceso debido a que no se deben colocar valores ya que no se
            continue
        }
        #Optimizar val según type
        switch($regData.type.toLower()){
           "string"        {
                #Eliminar el Escape de strings (\\ y \") de testo de exportación del registro
                $regData.val = $regData.val.Replace('\"','"')
                $regData.val = $regData.val.Replace("\\","\")
                $regData.val = [string]$regData.val.Replace('""','"')
                if($regData.val -eq '"'){
                   $regData.val = ""
                }
                $regData.type = "String"
            }
            
            "expandstring"  {
                if($regData.val.StartsWith("hex(2):")){
                    $regData.val  = $regData.val.Replace("hex(2):","")
                    $regData.val  = $regData.val.Replace(",00","")
                    $regData.val  = $regData.val.Replace("\","")
                    $regData.val  = $regData.val.Replace(" ","")
                    $regData.val  = $regData.val -Replace ("\s+", "")
                    $regData.val.Split(",") | % {[char]([convert]::toint16($_,16))} | % {$result = $result + $_}
                    $regData.val  = $result
                }else{
                    $regData.val  = [string]$regData.val
                }
                $regData.val  = [string]$regData.val
                $regData.type = "ExpandString"
                break
            }
            "dword"         {
                $regData.val  = $regData.val.ToString().Replace("dword:","")
                $regData.val  = [convert]::toint32($regData.val,16)
                $regData.type = "DWord"
                break
            }
            "binary"        {
                $regData.val  = $regData.val.Replace("hex:","")
                $regData.val  = $regData.val -Replace "\s+" , ""
                $regData.val  = $regData.val.Replace("\","")
                $regData.val  = $regData.val.Replace(" ","")
                $regData.val  = $regData.val.Split(',') | % { "0x$_"}
                $regData.val  = ([byte[]]$regData.val)
                $regData.type = "Binary"
                break
            }
            "none"          {
                $regData.val  = ([byte[]]@())
                $regData.type = "NONE"
                break
            }
            "multistring"   {
                #hex(7): = multistring
                $regData.val  = $regData.val.Replace("hex(7):","")
                $regData.val  = $regData.val.Replace(",00","")
                $regData.val  = $regData.val.Replace("\","")
                $regData.val  = $regData.val.Replace(" ","")
                $regData.val  = $regData.val -Replace ("\s+", "")
                $regData.val.Split(",") | % {[char]([convert]::toint16($_,16))} | % {$result = $result + $_}
                $regData.val  = $result
                $regData.type = "MultiString"
                break
            }
            "qword"         {
                # hex(b)  = Qword
                $regData.val  = $regData.val.ToString().Replace("hex(b):","")
                $regData.val  = $regData.val.Replace("\","")
                $regData.val  = $regData.val.Replace(" ","")
                $regData.val  = $regData.val -Replace ("\s+", "")
                $regData.val.Split(",") | % {$result = $_ + $result}
                [int64]$regData.val = [string]("0x"+$result)
                $regData.type = "QWord"
                break
            }
            "unknown"       {
                Write-Output "No se ha definido como pasar los datos del un valor tipo unknown. Terminado!"
                exit
                break
            }

            default         {
                Write-Output "$regData.type no es un tipo de datos reconocible en el registro. Terminado!"
                exit
            }
        }# Fin de bloque Switch del tipo y valor

        #ingreso en el registro
        if(Test-Path $regData.Path){
            Set-ItemProperty -path $regData.path -force -name $regData.name.trim("`"") -value $regData.val -type $regData.type
        }else{
            wError ("La ruta " + $regData.path + " NO existe.")
            $regData
            wInfo ("Si elimina una ruta asegurese que el codigo no contenga valores. ue solo venta el nombre de la ruta a eliminar")
            exit
        }

    }#Fin de process
} # Fin de function addToReg
