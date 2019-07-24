/// This class can be used to generate a url/cookie friendly token.
Class Frontier.Security.CookieSignature
{

/// Providing a value and secret, returns a token in the format:
/// <value>.<b64(hmac(sha512(value, secret)))>
/// The 'value' parameter is concatenated into the token in plain text. If you want to hide the info, you can encode/encrypt it before calling this method.
/// The 'secret' is the string key used by the encryption algorithm and should never be exposed.
ClassMethod Sign(value As %String, secret As %String) As %String
{
  return value_"."_$translate($System.Encryption.Base64Encode($System.Encryption.HMACSHA(512, value, secret), 1), "=/+$", "")
}

/// Takes a token returning the value portion if valid otherwise empty.
/// The 'token' parameter must be exactly what was generated by the Sign method.
/// The 'secret' must also be the same used to generated the token. It can also be a $list of secrets that must be tested against.
ClassMethod Unsign(token As %String, secret As %String) As %String
{
  
  if secret '= "" && $lv(secret) && ($ll(secret) > 1) {
    for i=1:1:$ll(secret) {
      set value = ..Unsign(token, $lg(secret, i))
      if value '= "" return value
    }
    
    return ""
  }
  
  set value = $piece(token, ".", 1)
  set mac = ..Sign(value, secret)

  if $$ConstantTimeCompare(mac, token) {
    return value
  }

  return ""

ConstantTimeCompare(a, b)
  if $length(a) '= $length(b) return 0
  for i=1:1:$length(a) {
    // Convert char to ASCII code and then to bitstring.
    set aChar = $factor($ascii($extract(a, i)))
    set bChar = $factor($ascii($extract(b, i)))
    set match = $bitlogic(aChar ^ bChar)
    set all = $bitlogic(all | match)
  }
  // 00000000 = valid
  return $bitfind(all, 1) = 0
}

}
