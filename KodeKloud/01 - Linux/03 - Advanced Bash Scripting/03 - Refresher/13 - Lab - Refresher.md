---
Curso: Advanced Bash Scripting
Modulo: Refresher
Tema: Lab - Refresher
Fecha de Inicio: 2026-05-22
Dificultad:
Tareas Totales: "8"
tags:
  - Advanced-Bash-Scripting
---
---
## 📊 Bitácora de Intentos
| Fecha      | Tiempo | Éxito |
| :--------- | :----- | :---- |
| `22/05/26` | 20 min | 50 %  |
|            |        |       |

4

Question 1 of 8

There is a script named `clone_project.sh` under `/home/bob/script` directory, make this script executable so that user `bob` can execute it, but you need not to execute the script as of now.


=======================
Question 2 of 8

When executed without passing a command line argument, the script returns an error message which might be unclear.  
  
To fix this, we will use a guard clause that checks if the value of a variable is empty, for example:  

```bash
if [[ -z "${var}" ]]; then
   echo "Variable is empty"
fi
```

  
  
This should be a straight forward implementation, as the value of a command line argument that isn’t passed defaults to empty string, making it suitable for this guard clause implementation.  
  
Please add a check to verify if the `project` variable is empty, if the `project` variable is empty then the script should print `Error: Git project is not specified` to the screen and should exit with status `1`.  
  
After making the changes, please try to execute the script without passing the command line arguments.


=============================
Question 3 of 8

Great, now that we created a guard clause to check if the command line argument at position `1` is being passed or not, let’s run the script again, but this time we’ll pass a git repository URL `https://github.com/kodekloudhub/webapp-color.git` as first argument and and `v2` branch as second argument.

====================

Question 4 of 8

Run the script again, but this time remove the branch argument (2nd argument). You will notice that although there is an error, but we still get the files count of the existing files on the `repo`, we need to figure out what is happening here. First identify the error its displaying.  

`Note:` If you will try to re-run the script multiple times the error message might change, so please notice the error message you got when you ran the script first time.

=================

Question 5 of 8

Git by itself, won’t produce an error if we don’t pass an argument to git checkout. The default behaviour of bash script is to assign an empty value to the command line arguments if not passed.  
  
Let’s add a fix to the script, so that we only do a git checkout if the branch variable contains a value. For this, we’re going to use the `-z` flag again with `if` statement, but this time it will be a little different.  
  
Since `git` uses a default branch as part of its normal behavior, the branch name should be an optional value. So instead of using the `if` statement as a `Guard Clause` technique, we will surround the git checkout function with an `if` statement. This way, `git checkout` will only run if we explicitly pass a value.  
  
Below is a technique we can use for this:  

```bash
if [[ ! -z "${var}" ]]; then
  echo "This variable isn't empty"
fi
```

  
  
Finally try to execute the script, it will not display any error even if you don't pass any branch argument.


======================

Question 6 of 8

We just fixed the error message on the script so that it runs fine when we don’t pass the 2nd argument.  
  
The reason simple, since `git` uses a default branch (mostly `master`) so we don’t need to explicitly pass a branch every time. We should pass a branch when we want to count the files in a specific branch.  
  
Let’s run the script now with branch name `mockbranch`  

```sh
./clone_project.sh https://github.com/kodekloudhub/webapp-color.git mockbranch
```

  
  
What is the error message you see now?  

A) Error: Branch mockbranch doesn't exist in https://github.com/kodekloudhub/webapp-color.git  
  
B) Error: Branch mockbranch doesn't exist  
  
C) Error: Branch mockbranch is invalid  
  
D) Error: Fetching branch mockbranch


=================


Question 7 of 8

_info_

The script still returns a file count because it counts the files from the existing checked out branch in the local repository.  
  
Ideally, we want to avoid running the files count function, as the script’s purpose is to return the files count for the given branch only if we pass the branch argument.  
  
If the given branch doesn’t exist, we should exit the script instead of allowing it to continue and returning a value from a different branch. This may lead us to believe the script worked, despite showing an error message. Let’s use one of the `one-liner` guard clause techniques we learned in the Guard Clause lecture.  
  
The `||` operator is used to run the command on its right only if the command on its left exits with a non-zero status (i.e., it encounters an error or fails to execute). Example:  
  

```sh
non_existent_command || echo "This line will be printed, as the command on the left doesn't exist"
```

  
  
  
In this specific example, when the shell attempts to execute `non_existent_command`, it will fail and produce a standard error message. Since the command on the left of the `||` operator exited with a `non-zero` status, the shell proceeds to execute the command on the right of the `||` operator, which is `echo "This line will be printed, as the command on the left doesn't exist"`.  
  
  
So, the shell prints the message `“This line will be printed, as the command on the left doesn’t exist”`. So, the `||` operator allows you to handle situations where a command might fail and perform an alternative action when that happens.


===================

Question 8 of 8

Let's update the `git_checkout` function to fail the script with `Error: Branch ${branch} doesn't exist in ${project}.` error message if the branch passed to the script doesn't exist in the repository. Also make sure it exits the script without counting the files.