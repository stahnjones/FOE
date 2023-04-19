Param(
 [Alias('c','total')][int]$currentTotalInvestment,
 [Alias('m', 'max')][int]$totalInvestmentToFlip,
 [Alias('b','beat')][int]$investorAmountToBeat=0
)

function SnipeGB{
 Param(
  [int]$curVal,
  [int]$maxVal,
  [int]$nextTier=0
 )
 return ([math]::Ceiling((($maxVal - $curVal) / 2 + ($nextTier/2))))
}

SnipeGB -curVal $currentTotalInvestment -maxVal $totalInvestmentToFlip -nextTier $investorAmountToBeat
