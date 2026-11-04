#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Wrapper entrypoint for FitnessReminderDaemon.
"""
import sys
import os

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

import daemon

if __name__ == "__main__":
    daemon.main()
