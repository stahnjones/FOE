Param(
 [switch]$save_cache
)

$cache_file="$PSScriptRoot\gbData.json"


$shortNames=@{
 Observatory='Obs'
 Temple_of_Relics='ToR'
 Oracle_of_Delphi='OoD'
 Galata_Tower='Galata'
 Tower_of_Babel='ToB'
 Statue_of_Zeus='Zeus'
 Colosseum='Colo'
 Lighthouse_of_Alexandria='LoA'
 Hagia_Sophia='HS'
 Cathedral_of_Aachen='CoA'
 St_Mark_s_Basilica='SMB'
 Notre_Dame='ND'
 Saint_Basil_s_Cathedral='SBC'
 Castel_del_Monte='CdM'
 Deal_Castle='DC'
 Frauenkirche_of_Dresden='FoD'
 Capitol='Cap'
 Royal_Albert_Hall='RAH'
 Chateau_Frontenac='CF'
 Alcatraz='Traz'
 Space_Needle='SN'
 Atomium='Atom'
 Cape_Canaveral='CC'
 The_Habitat='Hab'
 Lotus_Temple ='LT'
 Innovation_Tower='Inno'
 Truce_Tower='Truce'
 Voyager_V1='Voy'
 The_Arc='Arc'
 Rain_Forest_Project='RFP'
 Gaea_Statue='Gaea'
 Arctic_Orangery='AO'
 Seed_Vault='SV'
 Atlantis_Museum='AM'
 The_Kraken='Kra'
 The_Blue_Galaxy='BG'
 Terracotta_Army='TA'
 Himeji_Castle='HC'
 The_Virgo_Project='VP'
 Star_Gazer='SG'
 Space_Carrier='SC'
 Flying_Island='Island'
 AI_Core='Core'
}

if ($save_cache.IsPresent -or ! (test-path $cache_file)) {
 Retrieve-GbData
 $gbData|ConvertTo-Json -Depth 99 -Compress | sc $cache_file
} else {
 $gbData = gc $cache_file | ConvertFrom-Json
}

function CycleNames{
 $tName = $script:names[0]
 $script:names = $script:names[1..($script:names.Count - 1)]
 $script:names += $tName
}

function CycleSlots{
 $script:names = @()
 $script:sourceIDs=@()

 $slot=1
 while ($slot -le 9) {
  $tCkb=$grpNames.controls["ckbKeep$slot"]
  $tTxt=$grpNames.controls["txtName$slot"]
  if (! $tckb.Checked -and -not $tTxt.Text) {
   $nextCkb = $grpNames.controls["ckbKeep$($slot+1)"]
   $nextTxt = $grpNames.controls["txtName$($slot+1)"]
   if (! $nextCkb.Checked -and $nextTxt.text) {
    $tTxt.text = $nextTxt.text
    $nextTxt.text = ''
   }
  }
  $slot++
 }

 1..9|%{
  $tCkb = $grpNames.controls["ckbKeep$_"]
  if (! $tCkb.Checked) {
   $tName = $grpNames.controls["txtName$_"].text
   
   if ($tName) {
    $script:names += $tName
    $sourceIDs += $_
   }
  }
 }
 
 CycleNames

 foreach ($sourceID in $sourceIDs){
  $grpNames.controls["txtName$sourceID"].text = $script:names[$sourceIDs.indexof($sourceID)]
 }

 $numGBLvl.Value++
}

function Retrieve-GbData{
 Param([string]$url='https://foe.tools/foe-data/gbs-a85cea4.json')

 Write-Information "Downloading updated GB data from $url" -InformationAction Continue
 $script:gbData = IRM $url
}

Function Add-FormObject {
 Param(
  [alias('f')]$frm,
  [alias('t')]$objType,
  [alias('n')]$objName,
  [alias('l','left')]$x,
  [alias('top')]$y,
  [alias('w')]$width,
  [alias('h')]$height,
  [alias('a')][switch]$autoSize,
  [alias('am')]$autoSizeMode,
  [alias('tx')]$text,
  $tag,
  [alias('i')][float]$increment,
  [alias('d')][int]$decimals,
  $padding,
  $margin
 )

 if (!($frm -is "system.windows.forms.form" -or $frm -is "System.Windows.Forms.Control")) {
  if ($frm -is "string" -and (Get-Variable $frm -ValueOnly) -is "System.Windows.Forms.Control") {
   $frm = Get-Variable $frm -ValueOnly
  }
 }

 $tObj = New-Object "$swf.$objType"
 $tObj.Name = $objName
 if ($text){
  $tObj.text = $text
 }
 if ($x) {
  $tObj.left = $x
 }
 if ($y){
  $tObj.top = $y
 }
 if ($width){
  $tObj.width = $width
 }
 if ($height){
  $tObj.height = $height
 }
 if ($autoSize.IsPresent){
  $tObj.autosize = $true
 }
 if ($autoSizeMode){
  $tObj.autosizemode = $autoSizeMode
 }
 if ($tag){
  $tObj.tag = $tag
 }
 if ($increment) {
  $tObj.increment = $increment
 }
 if ($decimals) {
  $tObj.decimalPlaces = $decimals
 }
 if ($padding){
  if ($padding -is "hashtable") {
   $tObj.padding = $padding
  } else {
   $tObj.padding.all = $padding
  }
 }
 if ($margin){
  if ($margin -is "hashtable") {
   $tObj.margin = $margin
  } else {
   $tObj.margin.all = $margin
  }
 }

 $frm.controls.add($tObj)
 return $tObj
}

function Update-Slots{
 $gbName = $cmbGB.selectedItem
 $gbLvl = $numGBLvl.value
 $mult = $numMult.value

 if (! $gbName -or ! $gbLvl -or ! $mult) {return}

 $lvlData = $gbData.gbsData.$($gbName -replace(" |'", '_')).levels[$gbLvl - 1]
 1..5|%{
  $grpNames.controls["txtInvest$_"].text = [math]::Ceiling($lvlData.reward[$_-1].fp * $mult)
 }

 $ownerCost = $lvlData.cost - ((1..5|%{$grpNames.controls["txtInvest$_"].text})|Measure-Object -Sum).sum

 $txtOwnerCost.text = $ownerCost

}

function Copy-NamesToClipboard{
 $gbName = $cmbGB.selectedItem
 $gbLvl = $numGBLvl.value
 $mult = $numMult.value

 $lvlData = $gbData.gbsData.$($gbName -replace(" |'", '_')).levels[$gbLvl - 1]
 $owner = $txtOwner.text
 $ownerCost = $lvlData.cost - ((1..5|%{$grpNames.controls["txtInvest$_"].text})|Measure-Object -Sum).sum

 $header="$owner $($shortnames.($gbName -replace(" |'", '_')))  $($gbLvl -1) → $gbLvl"
 $investors=[string]::Join("`n", $grpNames.controls.where({$_.name -match "txtName" -and [int]($_.name.substring($_.name.length - 1)) -le 5 }).foreach({"$($_.name.substring($_.name.length - 1)): $($_.Text) - $($grpNames.controls["txtInvest$($_.name.substring($_.name.length - 1))"].text)" }))
 $footer="(self: $ownerCost)"

 "$header`n$investors`n$footer" | Set-Clipboard
}

function Show-ToolTip {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Windows.Forms.Control]$control,
        [string]$text = $null,
        [int]$duration = 1000
    )
    if ([string]::IsNullOrWhiteSpace($text)) { $text = $control.Tag }
    $pos = @{x=$control.Right; y=$control.Top}
    $obj_tt.Show($text,$this.parent, $pos, $duration)
}


$swf = "System.Windows.Forms"
$pad = 10

Add-Type -AssemblyName $swf

$form = New-Object "$swf.form"
$form.Text = "Power-Leveling Slot Cycling"
$form.Name = "PowerLeveling"
$form.AutoSize = $true
$form.AutoSizeMode = 'GrowAndShrink'
$form.Padding.Right = $pad
$grpNames = Add-FormObject $form -objType "GroupBox" -objName "grpNames" -x $pad -y $pad -autoSize -text "Lock      Name                                                      Invest" -margin $pad -padding $pad

1..9|%{
 $tCkb=Add-FormObject $grpNames -objType checkbox -objName "ckbKeep$_" -x $pad -y (($pad *($_+1)) + (20*($_-1))) -text $_ -autoSize -tag "Keep slot $_ during cycle"
 $tCkb.Add_MouseEnter({Show-ToolTip $this -text $this.tag})
 $tCkb.Add_MouseLeave({$obj_tt.Hide($this.parent)})

 $tTxt=Add-FormObject $grpNames -objType textbox -objName "txtName$_" -x ($tCkb.right + $pad) -y $tCkb.top -width 170

 if ($_ -le 5) {
  $tInv=Add-FormObject $grpNames -objType textbox -objName "txtInvest$_" -x ($tTxt.Right + $Pad *2) -y $tTxt.top -width 40 -margin @{right=10}
  $tInv.TabStop = $false
  $tInv.Enabled = $false
 }
}


$grpGB = Add-FormObject $form -objType GroupBox -objName grpGB -x ($grpNames.Right + $Pad*2) -y $grpNames.top -text "Victim:" -autosize -margin $pad -padding $pad

$lblOwner = Add-FormObject $grpGB -objType Label -objName lblOwner -x $pad -y ($pad * 2) -text "Name:" -autoSize
$txtOwner = Add-FormObject $grpGB -objType TextBox -objName txtOwner -x ($lblOwner.Right + $pad) -y ($lblOwner.top - 2) -width 175

$lblMult = Add-FormObject $grpGB -objType Label -objName lblMult -x ($txtOwner.right + $pad) -y ($lblOwner.top) -autoSize -text 'mult:'
$numMult = Add-FormObject $grpGB -objType NumericUpDown -increment 0.01 -decimals 2 -text 1.90 -x ($lblMult.Right + $pad) -y $txtOwner.top -w 50 -margin $pad
$numMult.Add_ValueChanged({Update-Slots})

$lblGB = Add-FormObject $grpGB -objType Label -objName lblGB -x ($pad) -y ($txtOwner.bottom + $pad ) -autoSize -text "GB:"
$cmbGB = Add-FormObject $grpGB -objType ComboBox -objName cmbGB -x ($lblGB.Right + $Pad) -y ($lblGB.top - 2) -width 150
$cmbGB.add_SelectedValueChanged({Update-Slots})

$gbData.gbs.PSObject.Properties.Name|sort|%{[void]($cmbGB.items.add($_ -replace('_', ' ') -replace(' s ', "'s ")))}

$lblGBLvl = Add-FormObject $grpGB -objType Label -objName lblGBLvl -x ($cmbGB.Right + $pad * 2) -y ($lblGB.top) -autoSize -text "→Lvl:"
$numGBLvl = Add-FormObject $grpGB -objType NumericUpDown -objName numGBLvl -x ($lblGBLvl.Right + $pad) -y $cmbGB.top -text 40 -w 40
$numGBLvl.Add_ValueChanged({Update-Slots})
$numGBLvl.Maximum=250

$lblOwnerCost = Add-FormObject $grpGB -objType Label -objName lblOwnerCost -x $pad -y ($cmbGB.bottom + $Pad) -autoSize -text "Owner cost:"
$txtOwnerCost = Add-FormObject $grpGB -objType TextBox -objName txtOwnerCost -x ($lblOwnerCost.right + $pad) -y ($lblOwnerCost.top - 2) -width 75

$btnCycle = Add-FormObject $form -objType button -objName btnCycle -text "Cycle Slots" -x $pad -y ($grpNames.Bottom + $pad*5) -autoSize
$btnCycle.add_Click({CycleSlots })
$btnCopy=(Add-FormObject $form -objType button -objName btnCopy -text "Copy to Clipboard" -x ($btnCycle.right + $Pad * 2) -y $btnCycle.top -autoSize)
$btnCopy.add_Click({Copy-NamesToClipboard})

$obj_tt = New-Object System.Windows.Forms.ToolTip $form.Container

$form.showdialog()
