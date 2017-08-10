#define ltrim(%str)       $zstrip(%str, "<W")
#define rtrim(%str)       $zstrip(%str, ">W")
#define trim(%str)        $zstrip(%str, "<>W")
#define IsSQLQuery(%str)  ($$$ucase($extract($$$trim(%str), 6)) = "SELECT")