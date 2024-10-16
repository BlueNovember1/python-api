from setuptools import setup, find_packages

setup(
    name='python-api',
    version='1.0.0',
    description='Prosta aplikacja Flask API',
    packages=find_packages(),
    install_requires=[
        'Flask==2.0.3'
    ],
)
