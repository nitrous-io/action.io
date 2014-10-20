__Backported from Lakshan's wiki action.io wiki entry (Nov 4, 2013)__

We use [Firepad](http://www.firepad.io/) for collaboration within the IDE. So you will need to create a [Firebase](http://firebase.com) account and add its auth keys in `.env` file in your development setup.

Also, make sure to add the following Security Rules to the Firebase database you create:

```json
{
  "rules": {
    "box": {
      "$boxID": {
        ".read": "auth.box_id == $boxID",
        ".write": "auth.box_id == $boxID"
      }
    }
  }
}
```
