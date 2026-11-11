(() => {
	'use strict';

	const nativeFetch = globalThis.fetch.bind(globalThis);
	const manifestSuffix = '.parts.json';

	function fetchOptionsFor(request) {
		return {
			cache: request.cache,
			credentials: request.credentials,
			signal: request.signal,
		};
	}

	async function loadSplitPackage(request, manifest) {
		if (
			!Number.isSafeInteger(manifest.size)
			|| manifest.size < 0
			|| !Array.isArray(manifest.parts)
			|| manifest.parts.length === 0
		) {
			throw new Error(`Invalid package manifest for '${request.url}'.`);
		}

		let expectedSize = 0;
		for (const part of manifest.parts) {
			if (typeof part.path !== 'string' || !Number.isSafeInteger(part.size) || part.size < 0) {
				throw new Error(`Invalid package part in manifest for '${request.url}'.`);
			}
			expectedSize += part.size;
		}

		if (expectedSize !== manifest.size) {
			throw new Error(`Package manifest size mismatch for '${request.url}'.`);
		}

		let partIndex = 0;
		let partBytesRead = 0;
		let currentPart = null;
		let reader = null;

		const body = new ReadableStream({
			async pull(controller) {
				while (true) {
					if (reader === null) {
						if (partIndex >= manifest.parts.length) {
							controller.close();
							return;
						}

						currentPart = manifest.parts[partIndex];
						const partUrl = new URL(currentPart.path, request.url);
						const response = await nativeFetch(partUrl, fetchOptionsFor(request));

						if (!response.ok || response.body === null) {
							throw new Error(`Failed loading package part '${currentPart.path}'.`);
						}

						partBytesRead = 0;
						reader = response.body.getReader();
						partIndex += 1;
					}

					const result = await reader.read();
					if (result.done) {
						if (partBytesRead !== currentPart.size) {
							throw new Error(`Package part size mismatch for '${currentPart.path}'.`);
						}
						reader = null;
						continue;
					}

					partBytesRead += result.value.byteLength;
					controller.enqueue(result.value);
					return;
				}
			},
			cancel(reason) {
				return reader?.cancel(reason);
			},
		});

		return new Response(body, {
			headers: {
				'Content-Length': String(manifest.size),
				'Content-Type': 'application/octet-stream',
			},
		});
	}

	globalThis.fetch = async (resource, options) => {
		const request = new Request(resource, options);
		const url = new URL(request.url);

		if (!url.pathname.endsWith('.pck')) {
			return nativeFetch(request);
		}

		const manifestUrl = `${url.href}${manifestSuffix}`;
		const manifestResponse = await nativeFetch(manifestUrl, fetchOptionsFor(request));

		if (manifestResponse.status === 403 || manifestResponse.status === 404) {
			return nativeFetch(request);
		}

		if (!manifestResponse.ok) {
			throw new Error(`Failed loading package manifest '${manifestUrl}'.`);
		}

		return loadSplitPackage(request, await manifestResponse.json());
	};
})();
