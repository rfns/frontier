#include %ZEN.Utils
#include %occErrors

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
#define OSSlash $case($$$isWINDOWS, 1: "\", : "/")
#define AssertClassExists(%o) return:'$isobject(%o) $$$ERROR($$$ClassDoesNotExist, %o)
#define NULL $s($$$isWINDOWS : "//./nul", 1: "/dev/null")
#define ObjectOrNull(%obj) $select($isobject(%obj) : %obj, 1: "null")