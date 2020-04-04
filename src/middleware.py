#!/usr/bin/env python
# -*- coding: utf-8 -*-

import subprocess

import click
import docker

cli = docker.from_env()


@click.command()
@click.option('-e', '--env', default='dev',
              type=click.Choice(['dev', 'prd'], case_sensitive=False),
              help='Sets an environment mode.')
def deploy(env):
    """
    Refresh docker containers and its volumes, aimed for development purposes.
    """
    if env == 'dev':
        click.secho('Deploy started.', fg='green')
        cc = cli.containers.list()
        [cli.api.remove_container(c.id, force=True) for c in cc]
        import ipdb
        ipdb.set_trace()
        click.secho('Deploy refreshed.', fg='green')
    else:
        try:
            subprocess.check_output(['poetry', 'build'])
        except subprocess.CalledProcessError as err:
            print(err.output.decode('utf-8'))
            exit(1)

#     exec {
#       standardOutput = logStream(LogLevel.INFO)
#       errorOutput = logStream(LogLevel.ERROR)
#       environment(PROJECT_NAME: rootProject.name)
#         .commandLine 'deploy-compose', // '--verbose',
#         // https://docs.docker.com/compose/extends/
#         '-f', path.manager, '-f', path.middleware,
#         '-p', rootProject.name,
#         '--project-directory', rootDir.name,
#         'up', '-V', '-d',
#         // '--abort-on-container-exit',
#         '--force-recreate',
#         '--remove-orphans'
#     }

# // Task 'build' execution is not able to handle '--parallel' flag
# task prod(group: 'deploy', dependsOn: [build]) {
#   description = 'Builds deploy images from project\'s packaged assets.'
#   final def propType = "${rootProject.group}.config.profile.type"
#
#   // Credentials' parametrization
#   final def keys = (findProperty('envFile') ?: Boolean.FALSE)
#     ? file(envPath).properties
#     : CredentialKey.values().collectEntries {
#     [("$it" as String): UUID.randomUUID().toString().digest('SHA-256')]
#   }
#
#   keys.putAll([
#     PROJECT_NAME: rootProject.name,
#     DOCKERFILE  : path.dockerfile]) // Must be relative
#
#   rootProject.subprojects
#     .findAll { p ->
#       !p.hasProperty(propType) ^ (p.findProperty(propType) == "APPLICATION")
#     }
#     .each { p ->
#
#       dependsOn p.tasks.find { 'build' }
#       mustRunAfter p.tasks.find { 'build' }
#
#
#       exec {
#         standardOutput = logStream(LogLevel.INFO)
#         errorOutput = logStream(LogLevel.ERROR)
#         // Middleware loading up should always recreate its containers
#         environment(*: keys,
#           MODULE_NAME: p.project.name)
#         commandLine 'deploy-compose',
#           '-f', path.middleware, '-f', "$p.projectDir/compose.deploy.yml",
#           '-p', rootProject.name,
#           '--project-directory', rootDir,
#           'up', '-d', '--build'
#       }
