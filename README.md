# cs-audit-reporting
This is a script that ingests internal payment process audit reports and returns actionable data.

## Reqs and Setup

### You need...

* node v0.10.33 (or thereabouts; YMMV) https://nodejs.org/
* LiveScript v1.3.1 (again, YMMV with other versions) http://livescript.net/

### Then do...

* Obtain code and navigate to that directory.
* Run `npm install`.

## How To Use

First set up your config file. Make sure it is located in your home folder and called `.cs-audit-reporting.js`. It should look something like this.

```js
module.exports = {
  "autopilot": true, // Attempt to automatically fill values from this file?
  "email-settings": "<full_path_to_email_config>",
  "organizationId": "<cybersource_orgId>",
  "username": "<cybersource_username>",
  //"proxy": "http://127.0.0.1:8888" // Fiddler default setup.
}
```

Then set up your email data in a json file:

```json
{
  "alwaysCopy": ["admin@example.com"],
  "singleMRNText": "There was a bad payment.",
  "multipleMRNText": "There were bad payments.",
  "locations": {
    "centralnowheresville": {
      "displayName": "Central Nowheresville",
      "siteNumber": 144,
      "emails": ["thisguy@example.com", "thatguy@example.com"]
    },
    
    ...
    
  }
}
```

Now you are ready to run. Navigate to the dir where `main.ls` lives. Then run with `lsc main <path to report>`, passing the file as an argument to main.
