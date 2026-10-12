# Source metadata coverage

Every one of the 701 script objects in the complete hierarchy was attempted with `script_read(should_read_entire_file=true)`. The `source_metadata_*.jsonl` files store derived references only: require expressions, declared named functions/signatures and named interface calls with returned-source line anchors. No native source bodies/bytecode are saved.

These rows are automated METADATA_ONLY inspection, not deep semantic review. Regex can miss multiline/dynamic dependencies, local assigned functions, returned anonymous closures or dynamically constructed action names. Named methods can belong to GUI/network/other objects; a row is not automatically a gameplay remote. Expressions are preserved as expressions, not falsely resolved to absolute modules. Returned line count includes saved/decompiler comments and is not meaningful complexity.

Deep findings live in subject docs and source ledgers; only those entries support behavior/formula/contract assertions. Read failures are stored explicitly; literal decimal dots in changelog and pet-render names conflict with the tool's dot-path resolution. They are not proof the hierarchy objects are absent or the sources themselves are empty. No prohibited Luau/path mutation workaround was used.
