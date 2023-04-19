function SnipeGB{
 Param(
  [int]$curVal,
  [int]$maxVal,
  [int]$nextTier=0
 )
 return ([math]::Ceiling((($maxVal - $curVal) / 2 + ($nextTier/2))))
}
