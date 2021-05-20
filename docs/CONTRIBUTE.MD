# CONTRIBUTE

Thank you for wanting to contribute to Railway! Since this would require you to use your own credentials and certificates, let's get you setup so that you can easily insert them before you start working, and them remove them after you are done, shall we?

### Bootstrap
First, run the bootstrap playbook:
```shell
ansible-playbook contribute_bootstrap.yml
```

This playbook will:
1 - Create a `railway-credentials` folder in the same folder that you clone `railway` to;
2 - Make a copy of the placeholder development vault to `railway-credentials`;
3 - Make a copy of the placeholder production vault to `railway-credentials`;

With this done, you can now go through STEP 5 of the INSTALL.MD file to get your credentials inserted.

### Teardown
After you are done and are ready to open your PR, run the teardown playbook:
```shell
ansible-playbook contribute_teardown.yml
```

This playbook will:
1 - Copy your current development vault to `railway-credentials`;
2 - Copy the placeholder development vault back to this project;
3 - Copy your current production vault to `railway-credentials`;
4 - Copy the placeholder production vault back to this project;
5 - Copy your current development key pair to `railway-credentials`;
6 - Clear the development key pair file;
7 - Copy your current development key pair to `railway-credentials`;
8 - Clear the development key pair file;

Then also run the teardown playbook to AWS, so it removes every resource that costs money:
```shell
ansible-playbook teardown_aws.yml
```

### Setup
If you need to make any changes to your PR, or want to work on something else, instead of doing STEP 5 all over again, you can just run the setup playbook:
```shell
ansible-playbook contribute_setup.yml
```

1 - Copy your current development vault back to this project;
3 - Copy your current production vault back to this project;
5 - Copy your current development key pair back to this project;
7 - Copy your current development key pair back to this project;

