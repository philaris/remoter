### When a client first connects:
# * client sends magicmsg_first_connection
# * server sends value of "secure" stored in the state (TRUE or FALSE)
# * client either responds "" or hangs up if it can't continue
# * key exchange if necessary
# * next operation is to check if server needs a password...

### Comm pattern
# * pattern is req/rep
# * client always goes send/recv (unless send.more=TRUE)
# * server always goes recv/send

send_unsecure <- function(data, send.more=FALSE)
{
  serialversion = getval(serialversion)
  if (is.null(serialversion))
    pbdZMQ::send.socket(getval(socket), data=data, send.more=send.more)
  else
    pbdZMQ::send.socket(getval(socket), data=data, send.more=send.more,
                        serialversion=serialversion)
}



send_secure <- function(data, send.more=FALSE)
{
  serialized <- serialize(data, NULL, version=getval(serialversion))
  encrypted <- sodium::auth_encrypt(serialized, getkey(private), getkey(theirs))
  send_unsecure(data=encrypted, send.more=send.more)
}



receive_unsecure <- function()
{
  msg <- pbdZMQ::receive.socket(getval(socket))
  
  if (identical(msg, magicmsg_first_connection))
  {
    first_receive()
    return(magicmsg_first_connection)
  }
  
  msg
}



receive_secure <- function()
{
  encrypted <- pbdZMQ::receive.socket(getval(socket))
  
  if (identical(encrypted, magicmsg_first_connection))
  {
    first_receive()
    return(magicmsg_first_connection)
  }
  
  raw <- sodium::auth_decrypt(encrypted, getkey(private), getkey(theirs))
  unserialize(raw)
}



remoter_send <- function(data, send.more=FALSE)
{
  if (getval(secure))
    send_secure(data=data, send.more=send.more)
  else
    send_unsecure(data=data, send.more=send.more)
}



remoter_receive <- function()
{
  if (getval(secure))
    receive_secure()
  else
    receive_unsecure()
}



first_send <- function()
{
  message('INFO: first_send entry')
  send_unsecure(magicmsg_first_connection)
  message('INFO: receive after first')
  security <- receive_unsecure()
  message('INFO: got security reply')
  print(dput(security))
  
  if (security && !has.sodium())
    stop("remoter server communications are encrypted but the 'sodium' package is not detected on the client.  Please install the 'sodium' package, or start an unsecure server.")
  else if (!security && has.sodium())
    cat("WARNING: server not secure; communications are not encrypted.\n")
  
  set(secure, security)
  
  if (getval(secure))
  {
    send_unsecure(NULL)
    setkey(theirs, receive_unsecure())
    send_unsecure(getkey(public))
  }
  else
    send_unsecure(NULL)
  
  invisible()
}



first_receive <- function()
{
  logprint(level="INIT", "Receiving first connection from client...", checkverbose=TRUE)
  logprint(level="INIT", paste("alerting that server", ifelse(getval(secure), "is", "isn't"), "secure"), checkverbose=TRUE)
  send_unsecure(getval(secure))
  
  logprint(level="INIT", "receiving security acknowledgement from client", checkverbose=TRUE)
  if (getval(secure))
  {
    receive_unsecure()
    logprint(level="AUTH", "sending server public key", checkverbose=TRUE)
    send_unsecure(getkey(public))
    logprint(level="AUTH", "receiving client public key", checkverbose=TRUE)
    setkey(theirs, receive_unsecure())
  }
  else
    receive_unsecure()
  
  invisible()
}
