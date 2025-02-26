## this script doesnt work properly

the cause is because it doesnt detect the subcription to the waf sevice, and because of that it will not add the domain to the waf service, if excecuted anyways will create the records in the DNS but the CNAME will be wrong

if you can make it work there are some instructions to follow to make it work:
1. in the waf add domain section its needed to add the ip of the domain that is going to be connected
2. when added should be added in the dns recordset, the ip of the ECS that is going to have the app
3. finally in the other recordset should be added the CNAME generated in step 1
