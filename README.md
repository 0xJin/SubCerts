# SubCerts

SubCerts is an automated tool designed to extract subdomains from certificate transparency logs using the crt.sh API. This tool allows security researchers, penetration testers, and developers to identify subdomains of a target domain by leveraging publicly available certificates.

![SubCerts Logo](path/to/your/image.png)

Once subdomains are identified, SubCerts uses `httpx` to probe each subdomain, collecting HTTP response codes and titles to provide a quick overview of the status and content of each subdomain. This allows users to efficiently identify live subdomains, potential entry points, or areas of interest for further investigation.

## Installation

### Clone the Repository

To get started, clone this repository to your local machine using `git`:

```bash
git clone https://github.com/0xJin/SubCerts.git
cd SubCerts
chmod +x *.sh
./setup.sh
./subcerts.sh -h
```

## Features:
- **Subdomain Extraction**: Utilizes crt.sh, a certificate transparency log search engine, to gather subdomains associated with a target domain.
- **HTTP Probing**: Automatically sends HTTP/HTTPS requests to each extracted subdomain using `httpx` and returns:
  - HTTP status codes
  - Page titles
  - Silent output for clean and organized results
- **Automation**: Run the tool with a simple command and get results efficiently without manual effort.
- **Flexible Output**: Optionally save the extracted subdomains and `httpx` results to a file for later review.

## How it Works:
1. **Extract Subdomains**: 
   - The tool sends a request to crt.sh to fetch all subdomains tied to the target domain's certificates.
   - It filters out any email addresses found in the results.
2. **HTTP Probing with httpx**:
   - For each extracted subdomain, `httpx` is used to probe the domain, displaying HTTP status codes and page titles.
3. **Loading Indicator**:
   - A visual indicator keeps you informed of the progress, and if the process takes longer than 60 seconds, you'll receive a message to expect a longer runtime.

## Usage

### Example Command:
To run SubCerts for a domain and save the results to a file:

```bash
./subcerts.sh -u example.com --output results.txt

