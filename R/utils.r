test_connection <- function(addr, port, ntries=10, sleeptime=1)
{
  message('INFO: test_connection entry')
  ctx <- pbdZMQ::init.context()
  socket <- pbdZMQ::init.socket(ctx, "ZMQ_REQ")
  addr <- pbdZMQ::address(addr, port)
  
  message('INFO: test_connection starting tries')
  for (i in ntries)
  {
    test <- tryCatch(
      pbdZMQ::connect.socket(socket, addr), 
      error=identity, warning=identity, message=identity
    )
    
    if (inherits(test, "simpleWarning"))
      Sys.sleep(sleeptime)
    else
      break
  }
  message('INFO: test_connection after tries')
  print(test)
  print(dput(test))
  
  rm(socket)
  rm(ctx)
  invisible(gc())
  
  if (inherits(test, "simpleWarning"))
    stop(
"Unable to connect to remote address.  Make sure that 
* the server is running and able to accept connections (e.g. forwarding ports), 
* the port argument is correct, 
* the remote address is correct.")
  
  invisible(TRUE)
}



validate_address <- function(addr)
{
  check.is.string(addr)
  
  if (grepl(addr, pattern="^.*://"))
    stop("Remote address should not include a protocol.")
  else if (grepl(addr, pattern=":"))
    stop("Remote address should not include ports.")
  
  addr
}



scrub_addr <- function(addr)
{
  if (grepl(addr, pattern="/$"))
    addr <- substr(addr, 1L, nchar(addr)-1L)
  
  addr
}



validate_port <- function(port, warn=FALSE)
{
  check.is.posint(port)
  check(port > 1023 && port < 65536)
  
  if (port != 0 && port < 49152 && warn)
    cat("WARNING: You are strongly encouraged to use port values between 49152 and 65536. See '?pbdZMQ::random_port' for details.")
  
  invisible(TRUE)
}



get_versions <- function()
{
  pkgs <- c("pbdZMQ", "remoter")
  ret <- lapply(pkgs, packageVersion)
  names(ret) <- pkgs
  
  ret
}



compare_versions <- function(client, server)
{
  if (client$pbdZMQ < server$pbdZMQ)
    return(FALSE)
  if (client$remoter < server$remoter)
    return(FALSE)
  
  TRUE
}



assert_nostop <- function(..., env = parent.frame())
{
  test <- tryCatch(check(...), error=identity)
  if (!is.logical(test))
  {
    if (iam("local") || getval(debug))
    {
      msg <- gsub(test, pattern="(^<assert|>$|Error: )", replacement="")
      remoter_client_stop(msg)
    }
    
    return(FALSE)
  }
  else
    TRUE
}



isFALSE <- function(x)
{
  identical(FALSE, x)
}



isWindows <- function()
{
  tolower(.Platform$OS.type) == "windows"
}



isRStudio <- function()
{
  tolower(.Platform$GUI) == "rstudio"
}



get_hostname = function()
{
  Sys.info()[["nodename"]]
}
