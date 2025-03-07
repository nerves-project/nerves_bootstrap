# SPDX-FileCopyrightText: 2016 Justin Schneck
#
# SPDX-License-Identifier: Apache-2.0
#
Mix.shell(Mix.Shell.Process)
File.rm_rf("test/tmp")
ExUnit.start()
