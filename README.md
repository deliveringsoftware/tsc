# tsc - Team Security as Code

It is *Security as Code*. Control the security of Azure DevOps with code. It is auditable and more secure.

One of the major complexity in the administration of Azure DevOps Services and Server, former Visual Studio Teams Services (VSTS) and Team Foundation Server (TFS), is to take care of security, what involves add user or delete, put into groups and give the right permissions... and don't go crazy managing that! Some companies give more permissions to users, other give restrict essentials permissions or have a heavy code of access.

Although it is possible to extract a report of the current permissions, you can not see the change history. The permissions are also scattered which makes the administration for a service desk department a pain.
 
The objective of **tsc** is set the the right permissions to users of Azure DevOps and mantain versioned and updated. 

The ideia is write a yaml file with the security structured, like this:

```
Org: 
  - name: deliveringsoftware
    projects:        
      - name: sandbox
        groups:
        - name: Contributors
          users:
          - name: Alan Turin
            email: a.turing@deliveringsoftware.com.br
          - name: Margaret Hamilton
            email: m.hamilton@deliveringsoftware.com.com
        - name: Project Administrators 
          users:
          - name: Emmanuel Brandão
            email: egomesbrandao@gmail.com
      - name: SBAdmin
        groups:
        - name: Project Administrators 
          users:
          - name: Margaret Hamilton
            email: m.hamilton@deliveringsoftware.com.br
```

---

We are doing live coding sessions in YouTube, just in portuguese (pt-BR), but who knows when we start do it in english; access the link: [Delivering Software - Toolmakers (Live Stream)](https://youtu.be/xZtUsEyESnY) 

---
