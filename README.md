# nmax
This nmap script saves time by automatically discovering open ports using the **Syn-Scan** and then runs a `-sCV` scan on the discovered ports, saving the **NMAP** type scan result.

### Usage
```
sudo ./nmax.sh [-v] <IP>
```
This will create a file named `<IP>_depth` having the **IP** as a full number without `.` (e.g 10101011_depth)
