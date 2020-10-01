# Wafer Thin Auth

If you want a simple, fairly thin auth system for your ChatTheatre/SkotOS game, you want [thin-auth](https://github.com/ChatTheatre/thin-auth). Thin-auth is a perfectly reasonable PHP server app. It likes being installed at a server-like path. It needs Apache and MariaDB configured in specific ways. But it does a reasonable job of a lot of things, using a fairly small amount of code. Billing? Check. Verifying for your app that billing happened? Check. Web interface for changing settings? Check. Reasonable security? Check.

This is not that application.

Wafer-thin-auth doesn't use a database. Or a web server. Or any real security.

You can run it in dev and it will cheerfully believe that all your users are paid up, and always right about their passwords. It is an eternal and negligent optimist. You should never, never use it production. There are large swaths of important functionality that it doesn't even begin to attempt.

Also, its code is far smaller and its dependencies far fewer than anything that would actually, like, function properly. 'Good' negligent optimism can be had for cheap!

However, if you want to do local development with [ChatTheatre's SkotOS](https://github.com/ChatTheatre/SkotOS) repo, your choices are to configure the real server-strength thing... Or stand up an eternal and negligent optimist of a server to assure your ChatTheatre-powered game that everything is fine.

Wafer-thin-auth is that negligent optimist. You're welcome.
