# xcode-open-on-github ⚙️

Quick Actions for Xcode to jump to a source code line on Github/Bitbucket or copy a permalink to clipboard.

#### 1️⃣ Open on Github

<p align="left">
  <img src="images/open_on_github.png" width="450px"/>
</p>

#### 2️⃣ Copy GitHub link to clipboard

<p align="left">
  <img src="images/copy_github_link_to_clipboard.png" width="450px"/>
</p>

#### 3️⃣ Open on Bitbucket

Works the same as **Open on Github** but constructs a Bitbucket URL (`/src/` path with `#lines-{start}:{end}` anchor).

#### 4️⃣ Copy Bitbucket link to clipboard

Works the same as **Copy GitHub link to clipboard** but constructs a Bitbucket permalink.

## Install

Just double-click the files in quick-actions directory to add them to the Services menu.

#### Pro Tip ®
You can create your own keyboard shortcuts for added actions:
1. Open **System Preferences > Keyboard**. Click the **Shortcuts** tab and select **Services** from the list on the left side.
2. Scroll all the way down the list of services. Under the **Text** heading you should find the quick actions you just added. Select it and click **Add Shortcut** to assign a global shortcut.

<p align="left">
  <img src="images/add_shortcut.png" width="450px"/>
</p>

## How it works?

Quick Actions for Xcode are AppleScript scripts. From the Xcode app we get a path of active document and selected lines. Using shell scripts we determine repository URL, current commit and top-level directory of a repository. All that allows constructing a GitHub link.

<table><tr><td>
  <img src="images/script.png" width="700px"/>
</td></tr></table>

## Author

Wojtek Lukaszuk [@wojteklu](http://twitter.com/wojteklu)

## License

This project is licensed under the terms of the MIT license. See the license file.
