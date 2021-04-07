For Docker Agent type,
1. create a project with the same project key mentioned in the specs yaml
2. make sure docker container has internet access
3. setup email server for bamboo to send notifications whenever the github repo get updated
    -> bamboo administration => communication => mail server
4. enable 'Allow anonymous users to trigger remote repository change detection and Bamboo Specs detection' in 
    -> bamboo administration => security settings => edit => mark 'Allow anonymous users to trigger remote repository change detection and Bamboo Specs detection' => save
5. now go to specs menu in the top
    -> specs => Set up Specs repository => select your project in build project => link bamboo-specs github repo => confirm
    -> copy the webhook URL provided and paste it in your github webhooks 
    -> your bamboo-specs github repo => settings => webhooks => add webhook
    * paste the URL in payload URL
    * make content type to application/json
    * secret (which you need to create from your user settings menu => developer settings => Personal access tokens => create token with required set of persions needed by bamboo to access the bamboo-specs github repo)
    * click on add webhook
    * check payload connection is successfull
6. now go to projects => 'your project' => project settings (will be availble in right corner) => Bamboo specs repositories => add repo
