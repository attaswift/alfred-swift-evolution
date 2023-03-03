# 2.1.0 (2023-03-03)

Bugfixes and improvements:

* Fix broken proposal retrieval by adapting to data format and URL changes on swift.org.

* The proposal title is now displayed more prominently in Alfred (together with the proposal ID).

* New actions in Alfred:
  * Hold down Command to copy the proposal title to the clipboard.
  * Hold down Shift+Command to copy a Markdown link to the proposal to the clipboard.
  * (To copy the URL, hit Tab on a proposal and select Copy as Plain Text from the menu. This is not a new feature.)

* The script now forwards four variables to Alfred that can be used in subsequent workflow actions:
  * `proposal_id` (e.g. "SE-0304")
  * `proposal_title` ("Structured concurrency")
  * `proposal_status` ("Implemented")
  * `proposal_url` ("https://github.com/apple/swift-evolution/blob/main/proposals/0304-structured-concurrency.md")

  If you want to customize the workflow for your needs, you can use these variables in your actions. Refer to the "Copy Markdown link" action for an example.

* Display more detailed error messages in Alfred on network or parsing failures.

# 2.0.1 (2017-02-20)

This is a bugfix release with the following changes:

* The query string is now case insensitive, as it should be.
* You can now search for proposals using the internal name of a
  particular proposal status (such as `.rejected` or
  `.acceptedWithRevisions`).
* You now have to insert a space between <kbd>se</kbd> and your
  query string. Previously, the workflow also triggered for queries
  such as <kbd>setup</kbd>, which was not a good idea.
* The timing of how the script is run when you modify the query
  string has been tweaked.

# 2.0.0 (2017-02-20)

This third release of `alfred-swift-evolution` contains the following improvements:

* The script implementing the workflow is now written in Swift.
* Proposal information is now downloaded from the JSON API behind
  the official [Swift evolution review status page][status].
* Alfred now displays a list of matching proposals, not just a
  generic item for running the actual lookup.
* Matching proposals are now listed with their title and current
  status.
* You can filter proposals by keyword or status, not just by
  proposal number.

[status]: https://apple.github.io/swift-evolution/

# 1.1.0 (2016-09-26)

This release updates the way proposals are retrieved to follow
changes in the official swift-evolution repository.

# 1.0.0 (2016-08-02)

Initial release, written in Python.
