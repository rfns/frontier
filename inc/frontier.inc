#include %ZEN.Utils

#define ltrim(%str)       $zstrip(%str, "<W")
#define rtrim(%str)       $zstrip(%str, ">W")
#define trim(%str)        $zstrip(%str, "<>W")
#define trimQuote(%str)   $zstrip(%str, "<>", $c(34))
#define IsSQLQuery(%str)  ($$$ucase($extract($$$trim(%str), 6)) = "SELECT")
#define KeyGroup(%requestKey)  $zstrip($zstrip(%requestKey, "<=N"), "=>N")
#define KeyIndex(%requestKey)  $zstrip($zstrip(%requestKey, "<=N"), "<=A")
#define FormatBoolean(%value) $case(%value, 1: "true", 0: "false", : %value)
#define BooleanToBinary(%value) $case(%value, "true": 1, "false": 0, : %value)
#define NormalizeClassName(%cn) if $l(%cn, ".") = 1 && ($e(%cn) = "%") set %cn = "%Library."_$e(%cn, 2, *)