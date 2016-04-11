# Galera

## To prevent the autorebuild feature you should do

    crm_resource unmanage clone_p_mysql

## To re-enable autorebuild feature you should do

    crm_resource manage clone_p_mysql

## To check GTID and SEQNO across all nodes saved in Corosync CIB you should do

    cibadmin --query --xpath "//nodes/*/*/nvpair[@name=\"gtid\"]"

## To try an automated reassemble without reboot if cluster is broken just issue

    crm resource restart clone_p_mysql

## To remove all GTIDs and SEQNOs from Corosync CIB and allow the OCF script to reread the data from the grastate.dat file, you should do

    cibadmin --delete-all --query --xpath "//nodes/*/*/nvpair[@name=\"gtid\"]" --force
