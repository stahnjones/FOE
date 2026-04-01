Param(
 [switch]$save_cache,
 [int]$num_slots=15
)
if (! "$PSScriptRoot" -or $PSScriptRoot -eq '') {$ScriptRoot = '.'} else {$ScriptRoot = $PSScriptRoot}
$gbdata_url="https://foe.tools/foe-data/gbs-743bb34.json" #update as needed
$miscdata_url="https://foe.tools/_nuxt/826c83c.js" # update as needed - for short names look for main_menu.home / main_menu.register / etc, foe_data.gb_short comes later in that list
$cache_file="$ScriptRoot\gbData.json"
$cache_file_2="$ScriptRoot\shortData.json"


function Retrieve-GbData{
 Param([string]$url=$script:gbdata_url)

 Write-Information "Downloading updated GB data from $url" -InformationAction Continue
 try{
  $script:gbData = IRM $url
   return $true
 } catch {
   return $false
 }
}

function Retrieve-ShortData{
 Param([string]$url=$script:miscdata_url)

  $fdgs='foe_data.gb_short'
  Write-Information "Downloading updated GB Short Name data from $url" -InformationAction Continue
  try {
    $short = iwr $url
    $short_content = $short.RawContent
    #$short_start = $short_content.IndexOf($fdgs,$short_content.IndexOf($fdgs)+20) - 1
    $short_start = $short_content.IndexOf("`"$fdgs")
    $short_len = $short_content.IndexOf("`"foe_data.goods", $short_start) - 1 - $short_start
    $script:shortnames=$short_content.Substring($short_start, $short_len) -replace('^', '{') -replace('$', '}') -replace("$fdgs.")|convertfrom-json
    return $true
  } catch {
    return $false
  }
}

<#
$shortnames=@'
{"Observatory":"Obs","Temple_of_Relics":"ToR","Oracle_of_Delphi":"OoD","Tower_of_Babel":"ToB","Statue_of_Zeus":"Zeus","Colosseum":"Colosseum","Lighthouse_of_Alexandria":"LoA","Hagia_Sophia":"HS","Cathedral_of_Aachen":"CoA",
 "St_Mark_s_Basilica":"SMB","Notre_Dame":"ND","Saint_Basil_s_Cathedral":"SBC","Castel_del_Monte":"CdM","Deal_Castle":"Deal","Frauenkirche_of_Dresden":"FoD","Capitol":"Capitol","Royal_Albert_Hall":"RAH","Chateau_Frontenac":"CF","Alcatraz":"Traz",
 "Space_Needle":"SN","Atomium":"Atom","Cape_Canaveral":"CC","The_Habitat":"Hab","Lotus_Temple":"LT","Innovation_Tower":"Inno","Truce_Tower":"Truce","Voyager_V1":"Voyager","The_Arc":"Arc","Rain_Forest_Project":"RFP","Gaea_Statue":"Gaea",
 "Arctic_Orangery":"AO","Seed_Vault":"SV","Atlantis_Museum":"AM","The_Kraken":"Kra","The_Blue_Galaxy":"BG","Terracotta_Army":"TA","Himeji_Castle":"HC","The_Virgo_Project":"VP","Star_Gazer":"SG","Space_Carrier":"SC","Flying_Island":"Island","AI_Core":"Core",
 "Galata_Tower":"Galata","Saturn_VI_Gate_PEGASUS":"Pegasus","Saturn_VI_Gate_CENTAURUS":"Centaurus","Saturn_VI_Gate_HYDRA":"Hydra","Stellar_Warship":"Warship","Cosmic_Catalyst":"Catalyst"}
'@ | ConvertFrom-Json
#>


if ($save_cache.IsPresent -or ! (test-path $cache_file) ) {
 if (Retrieve-GbData -url $gbdata_url) {
  $gbData|ConvertTo-Json -Depth 99 -Compress | sc $cache_file
 }
 if (Retrieve-ShortData -url $miscdata_url) {
  $script:shortnames|ConvertTo-Json -Compress | sc $cache_file_2
 }
} else {
 $gbData = gc $cache_file | ConvertFrom-Json
 $shortnames = gc $cache_file_2 | ConvertFrom-Json
}

function CycleNames{
 Param([string[]]$nameList)

 return ($nameList[1..$nameList.Count] + $nameList[0])
}

function CycleSlots{ 

 #moved here to allow checking of new level slot amounts against spend limits
 $numGBLvl.Value++

 $script:unlockednames = @()
 #                        $grpNames.Controls.Where({$_.name -match '^txtName' -and $_.text}).foreach({$_.text})
 #$script:sourceIDs=@()

 #remove empties -> compact unchecked list
 $slot=1
 $activeSlotMax=0
 while ($slot -le $num_slots) {
  $tCkb=$grpNames.controls["ckbKeep$slot"]
  $tTxt=$grpNames.controls["txtName$slot"]
  if (! $tckb.Checked -and -not $tTxt.Text) {
   $nextCkb = $grpNames.controls["ckbKeep$($slot+1)"]
   $nextTxt = $grpNames.controls["txtName$($slot+1)"]
   if (! $nextCkb.Checked -and $nextTxt.text) {
    $tTxt.text = $nextTxt.text
    $nextTxt.text = ''
   }
  } elseif (! $tckb.Checked) {
   #not checked but has a value
   $script:unlockednames+=$tTxt.Text
   $activeSlotMax = $slot
  } else {
   #lock box is checked
  }
  $slot++
 }


 $alreadyCycled = $false
 1..$activeSlotMax |%{   #only loop over the name boxes where there is a value
  $idx = $_
  $cycleNames = $script:unlockednames
  #check if slot is locked
  $tCkb = $grpNames.controls["ckbKeep$idx"]
  if (! $tCkb.Checked) {
   $cyclecount=1
   if (! $alreadyCycled) {$script:unlockednames = CycleNames $script:unlockednames}
   $foundNext = $false

   while (! $foundNext -and $cyclecount -le ($script:unlockednames.Count)) {
    if (($idx -le 5) -and ((checkLimit $script:unlockednames[0]) -lt [int32]($grpNames.controls["txtInvest$idx"].text))) {
     $cyclecount++
     $script:unlockednames = CycleNames $script:unlockednames
     $alreadyCycled = $true
    } else {
     $foundNext = $true
     $alreadyCycled = $true
     $slotName = $script:unlockednames[0]
     $grpNames.controls["txtName$idx"].text = $slotName
     $script:unlockednames = @($script:unlockednames.where({$_ -ne $slotName}))
    }
   }

   if (! $foundNext) {
     [System.Windows.Forms.MessageBox]::Show("All slots have been cycled through and no more slots can be filled based on FP spend limits specified.","Cycle Slots problem",'OK','Exclamation','Button1')
   }
  } else {
   #lock box is checked

  }
 }

 Update-Slots
 
 #foreach ($sourceID in $sourceIDs){
 # $grpNames.controls["txtName$sourceID"].text = $script:names[$sourceIDs.indexof($sourceID)]
 #}

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
  $margin,
  [switch]$shrink,
  [switch]$disabled
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
  if ($shrink.IsPresent -and $tObj.AutoSizeMode) {
   $tObj.AutoSizeMode="GrowAndShrink"
  } else {
   #$tObj.AutoSizeMode="GrowOnly"
  }
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
 if ($disabled.IsPresent -and $tObj.enabled) {
  $tObj.enabled = $false
 }

 $frm.controls.add($tObj)
 return $tObj
}

function Update-Slots{
 $gbName = $cmbGB.selectedItem
 $gbLvl = $numGBLvl.value
 #$mult = $numMult.value
 if (! $gbName -or ! $gbLvl <#-or ! $mult#>) {
  foreach ($btn in @($form.controls.where({$_.name -like "btn*"}) )){
   $btn.enabled = $false
  }
  return
 }

 $lvlData = $gbData.gbsData.$($gbName -replace(" |'", '_')).levels[$gbLvl - 1]
 $numGBLvl.Maximum=$gbData.gbsData.$($gbName -replace(" |'", "_")).levels[-1].level
 1..5|%{
  $playerName = $grpNames.controls["txtName$_"].text
  #$tMult = $grpNames.controls["numMult$_"].value
  $tMult =  $grpCfg.controls["numCfgMult$($grpCfg.Controls.Where({$_.text -eq $playerName})[0].tag)"].value
  if (! $tMult) {$tMult = 1.9}
  $grpNames.controls["lblMult$_"].text = "($("{0:F3}" -f $tMult))"
  $tInvestAmt=[math]::Ceiling($lvlData.reward[$_-1].fp * $tMult)
  if ($tInvestAmt -eq 0) {$tInvestAmt = 1}
  $grpNames.controls["txtInvest$_"].text = $tInvestAmt
 }

 $ownerCost = $lvlData.cost - ((1..5|%{$grpNames.controls["txtInvest$_"].text})|Measure-Object -Sum).sum

 $txtOwnerCost.text = $ownerCost

 foreach ($btn in @($form.controls.where({$_.name -like "btn*"}) )){
   $btn.enabled = $true
 }

}

function checkLimit{
 Param([string]$playerName)

 $playerLimit = $grpCfg.controls["numCfgLimit$($grpCfg.Controls.Where({$_.text -eq $playerName})[0].tag)"].value

 if ($playerLimit) {return $playerLimit} else {return 1500000}
}

function Copy-NamesToClipboard{
 $gbName = $cmbGB.selectedItem
 $gbLvl = $numGBLvl.value
 #$mult = $numMult.value

 $lvlData = $gbData.gbsData.$($gbName -replace(" |'", '_')).levels[$gbLvl - 1]
 $owner = $txtOwner.text
 $ownerCost = $lvlData.cost - ((1..5|%{$grpNames.controls["txtInvest$_"].text})|Measure-Object -Sum).sum

 $header="$owner $($shortnames.($gbName -replace(" |'", '_')))  $($gbLvl -1) ? $gbLvl"
 $investors=[string]::Join("`n", $grpNames.controls.where({$_.name -match "txtInvest" -and $_.text}).foreach({
   $playerName=$grpNames.controls["txtName$($_.tag)"].Text;
   $playerChecked=$grpNames.controls["ckbKeep$($_.tag)"].checked

   $pMult =  $grpCfg.controls["numCfgMult$($grpCfg.Controls.Where({$_.text -eq $playerName})[0].tag)"].value
   if (! $pMult) {$pMult=1.9}
   "P$($_.tag)$(if ($playerChecked) {"??"}): $playerName $(if ($pMult -ne '1.900' ) {"($("{0:F3}" -f $pMult))"}) - $($_.text)" }))
 $footer="(self: $ownerCost)"

 "$header`n$investors`n$footer" | Set-Clipboard
}

function Copy-NamesToClipboard2{
 Param([switch]$doMult)
 $gbName = $cmbGB.selectedItem
 $gbLvl = $numGBLvl.value
 #$mult = $numMult.value
 $mult=1.9

 $lvlData = $gbData.gbsData.$($gbName -replace(" |'", '_')).levels[$gbLvl - 1]
 $owner = $txtOwner.text

 $slots=$lvlData.reward
 
 $outStr="$owner $($shortnames.($gbName -replace(" |'", '_')))  $($gbLvl -1) ? $gbLvl"
 5..1|%{
   # copy check-box-checked items only!
   if ($grpNames.controls["ckbKeep$_"].checked) {
     if ($doMult.IsPresent) {
      $outStr+= " P$_ ( $($grpNames.controls["txtInvest$_"].text) )"
     } else {
      $outStr+= " P$_ ( $([math]::Ceiling((($slots[$_ - 1].fp)*$mult))) )"
     }
   }
 }

 $outStr | Set-Clipboard
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

1..$num_slots|%{
 $tCkb=Add-FormObject $grpNames -objType checkbox -objName "ckbKeep$_" -x $pad -y (($pad *($_+1)) + (20*($_-1))) -text $_ -autoSize -tag "Keep slot $_ during cycle"
 $tCkb.Add_MouseEnter({Show-ToolTip $this -text $this.tag})
 $tCkb.Add_MouseLeave({$obj_tt.Hide($this.parent)})

 $tTxt=Add-FormObject $grpNames -objType textbox -objName "txtName$_" -x ($tCkb.right + $pad) -y $tCkb.top -width 170 -tag $_
 $tTxt.Add_Leave({update-slots})
 
 if ($_ -le 5) {
  $tInv=Add-FormObject $grpNames -objType textbox -objName "txtInvest$_" -x ($tTxt.Right + $Pad *2) -y $tTxt.top -width 40 -margin @{right=10} -tag $_
  $tInv.TabStop = $false
  $tInv.Enabled = $false
  $tLbl = Add-FormObject $grpNames -objType label -objName "lblMult$_" -x ($tTxt.Right - 50) -y ($tInv.top + 2) -width 50 -height 25 -tag $_ -text '' -autoSize
  $tLbl.BackColor = $tTxt.BackColor
  $tLbl.BringToFront()
  <#
  $tMult=Add-FormObject $grpNames -objType numericUpDown -objName "numMult$_" -increment 0.01 -decimals 2 -text 1.90 -x ($tInv.Right + $Pad) -y $tInv.top -w 50 -margin $pad -tag $_
  $tMult.Add_ValueChanged({Update-Slots})
  #>
 }
}


$grpGB = Add-FormObject $form -objType GroupBox -objName grpGB -x ($grpNames.Right + $Pad*2) -y $grpNames.top -text "Victim:" -autosize -margin $pad -padding $pad

$lblOwner = Add-FormObject $grpGB -objType Label -objName lblOwner -x $pad -y ($pad * 2) -text "Name:" -autoSize
$txtOwner = Add-FormObject $grpGB -objType TextBox -objName txtOwner -x ($lblOwner.Right + $pad) -y ($lblOwner.top - 2) -width 175
<#
$lblMult = Add-FormObject $grpGB -objType Label -objName lblMult -x ($txtOwner.right + $pad) -y ($lblOwner.top) -autoSize -text 'mult:'
$numMult = Add-FormObject $grpGB -objType NumericUpDown -increment 0.01 -decimals 2 -text 1.90 -x ($lblMult.Right + $pad) -y $txtOwner.top -w 50 -margin $pad
$numMult.Add_ValueChanged({Update-Slots})
#>

$lblGB = Add-FormObject $grpGB -objType Label -objName lblGB -x ($pad) -y ($txtOwner.bottom + $pad ) -autoSize -text "GB:"
$cmbGB = Add-FormObject $grpGB -objType ComboBox -objName cmbGB -x ($lblGB.Right + $Pad) -y ($lblGB.top - 2) -width 150
$cmbGB.Sorted = $true
$cmbGb.AutoCompleteMode = 'Append'
$cmbGB.AutoCompleteSource = 'ListItems'
$cmbGB.add_SelectedValueChanged({Update-Slots})

$gbData.gbs.PSObject.Properties.Name|%{[void]($cmbGB.items.add($_ -replace('_s_', "'s ") -replace('_', ' ') ))}

$lblGBLvl = Add-FormObject $grpGB -objType Label -objName lblGBLvl -x ($cmbGB.Right + $pad * 2) -y ($lblGB.top) -autoSize -text "?Lvl:"
$numGBLvl = Add-FormObject $grpGB -objType NumericUpDown -objName numGBLvl -x ($lblGBLvl.Right + $pad) -y $cmbGB.top -text 40 -w 50
$numGBLvl.Add_ValueChanged({Update-Slots})
$numGBLvl.Maximum=250

$lblOwnerCost = Add-FormObject $grpGB -objType Label -objName lblOwnerCost -x $pad -y ($cmbGB.bottom + $Pad) -autoSize -text "Owner cost:"
$txtOwnerCost = Add-FormObject $grpGB -objType TextBox -objName txtOwnerCost -x ($lblOwnerCost.right + $pad) -y ($lblOwnerCost.top - 2) -width 75

$btnCycle = Add-FormObject $form -objType button -objName btnCycle -text "Cycle Slots" -x $pad -y ($grpNames.Bottom + $pad*5) -autoSize -shrink -disabled
$btnCycle.add_Click({CycleSlots })
$btnCopy=(Add-FormObject $form -objType button -objName btnCopy -text "Copy as PL" -x ($btnCycle.right + $Pad ) -y $btnCycle.top -autoSize -shrink -disabled)
$btnCopy.add_Click({Copy-NamesToClipboard})
$btnCopy2=(Add-FormObject $form -objType button -objName btnCopy2 -text "1.9" -x ($btnCopy.right + $Pad ) -y $btnCycle.top -autoSize -shrink -disabled)
$btnCopy2.add_Click({Copy-NamesToClipboard2})

$btnCopy3=(Add-FormObject $form -objType button -objName btnCopy2 -text "1.9x" -x ($btnCopy2.right + $Pad ) -y $btnCycle.top -autoSize -shrink -disabled)
$btnCopy3.add_Click({Copy-NamesToClipboard2 -doMult})


#switch to grpPlayerInfo, add a numericupdown per player for multiplier, default to 1.90
$grpCfg = Add-FormObject $form -objType GroupBox -objName grpCfg -x ($grpGB.left ) -y ($grpGB.bottom + $pad *3 ) -autoSize -text 'Player Config                              FP Limit             Mult'
1..$num_slots|%{

 $tTxt=Add-FormObject $grpCfg -objType textbox -objName "txtCfgName$_" -x ($pad) -y (($pad *($_+1)) + (20*($_-1))) -width 140 -tag $_
 $tnumLim=Add-FormObject $grpCfg -objType numericUpDown -objName "numCfgLimit$_" -increment 1 -decimals 0 -text '' -x ($tTxt.Right + $Pad) -y $tTxt.top -w 65 -margin $pad -tag $_
 $tnumLim.Maximum = 1000000
 $tnumLim.add_Enter({Param($s,$e)$this.Select(0, $this.text.length)})
 $tnumLim.add_Click({Param($s,$e)$this.Select();$this.Select(0, $this.text.length)})

 $tMult=Add-FormObject $grpCfg -objType numericUpDown -objName "numCfgMult$_" -increment 0.001 -decimals 3 -text 1.90 -x ($tnumLim.Right + $Pad) -y $tnumLim.top -w 60 -margin $pad -tag $_
 $tMult.Add_ValueChanged({Update-Slots})
}





$obj_tt = New-Object System.Windows.Forms.ToolTip $form.Container

$form.showdialog()
