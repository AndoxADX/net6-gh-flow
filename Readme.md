# GH CLI, AZ cli, pwsh, .net 6, bicep
<!-- https://betterprogramming.pub/devops-for-net-6-0-7fae47cec014 -->
<!-- https://blog.novanet.no/infrastructure-as-code-with-bicep-and-github-actions/ -->
<!-- https://www.cloudninja.nu/post/2021/06/getting-started-with-github-actions-and-bicep-part-2/ -->

az deployment sub what-if -n dev -f bicep\deploy.bicep --parameters bicep\deploy.parameters.json